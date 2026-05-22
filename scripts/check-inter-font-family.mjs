#!/usr/bin/env node

import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { relative, resolve } from 'node:path';
import ts from 'typescript';

const repoRoot = process.cwd();
const defaultRoots = ['App.tsx', 'src'];
const textStyleProperties = new Set([
  'fontFamily',
  'fontSize',
  'fontStyle',
  'fontWeight',
  'includeFontPadding',
  'letterSpacing',
  'lineHeight',
  'textAlign',
  'textDecorationLine',
  'textTransform',
]);

const expectedFontFamily = 'Inter';

function collectSourceFiles(paths) {
  const files = [];

  for (const path of paths) {
    const absolutePath = resolve(repoRoot, path);

    if (!existsSync(absolutePath)) {
      continue;
    }

    const stats = statSync(absolutePath);

    if (stats.isDirectory()) {
      for (const child of readdirSync(absolutePath)) {
        files.push(...collectSourceFiles([resolve(absolutePath, child)]));
      }
      continue;
    }

    if (/\.[cm]?[tj]sx?$/.test(absolutePath)) {
      files.push(absolutePath);
    }
  }

  return files;
}

function unwrapExpression(expression) {
  let current = expression;

  while (
    ts.isAsExpression(current) ||
    ts.isSatisfiesExpression(current) ||
    ts.isTypeAssertionExpression(current) ||
    ts.isParenthesizedExpression(current)
  ) {
    current = current.expression;
  }

  return current;
}

function getPropertyName(name) {
  if (
    ts.isIdentifier(name) ||
    ts.isStringLiteral(name) ||
    ts.isNumericLiteral(name)
  ) {
    return name.text;
  }

  return null;
}

function getObjectProperties(expression) {
  const unwrapped = unwrapExpression(expression);

  if (!ts.isObjectLiteralExpression(unwrapped)) {
    return null;
  }

  return unwrapped.properties.filter(ts.isPropertyAssignment);
}

function collectStringBindings(sourceFile) {
  const bindings = new Map();

  function readLiteral(expression) {
    const unwrapped = unwrapExpression(expression);

    if (ts.isStringLiteralLike(unwrapped)) {
      return unwrapped.text;
    }

    return null;
  }

  function visit(node) {
    if (
      ts.isVariableDeclaration(node) &&
      ts.isIdentifier(node.name) &&
      node.initializer
    ) {
      const literal = readLiteral(node.initializer);

      if (literal != null) {
        bindings.set(node.name.text, literal);
        return;
      }

      const properties = getObjectProperties(node.initializer);

      if (properties != null) {
        for (const property of properties) {
          const propertyName = getPropertyName(property.name);
          const propertyValue = readLiteral(property.initializer);

          if (propertyName != null && propertyValue != null) {
            bindings.set(`${node.name.text}.${propertyName}`, propertyValue);
          }
        }
      }
    }

    ts.forEachChild(node, visit);
  }

  visit(sourceFile);
  return bindings;
}

function isStyleSheetCreateCall(node) {
  if (!ts.isCallExpression(node)) {
    return false;
  }

  const expression = node.expression;

  return (
    ts.isPropertyAccessExpression(expression) &&
    expression.name.text === 'create' &&
    ts.isIdentifier(expression.expression) &&
    expression.expression.text === 'StyleSheet'
  );
}

function resolveFontFamily(expression, bindings) {
  const unwrapped = unwrapExpression(expression);

  if (ts.isStringLiteralLike(unwrapped)) {
    return unwrapped.text;
  }

  if (ts.isIdentifier(unwrapped)) {
    return bindings.get(unwrapped.text) ?? null;
  }

  if (
    ts.isPropertyAccessExpression(unwrapped) &&
    ts.isIdentifier(unwrapped.expression)
  ) {
    return (
      bindings.get(`${unwrapped.expression.text}.${unwrapped.name.text}`) ??
      null
    );
  }

  return null;
}

function findFontFamilyIssues(filePath) {
  const sourceText = readFileSync(filePath, 'utf8');
  const sourceFile = ts.createSourceFile(
    filePath,
    sourceText,
    ts.ScriptTarget.Latest,
    true,
    filePath.endsWith('.tsx') || filePath.endsWith('.jsx')
      ? ts.ScriptKind.TSX
      : ts.ScriptKind.TS,
  );
  const bindings = collectStringBindings(sourceFile);
  const issues = [];

  function report(node, styleName, message) {
    const { line, character } = sourceFile.getLineAndCharacterOfPosition(
      node.getStart(sourceFile),
    );

    issues.push({
      column: character + 1,
      file: relative(repoRoot, filePath),
      line: line + 1,
      message,
      styleName,
    });
  }

  function visit(node) {
    if (isStyleSheetCreateCall(node)) {
      const stylesObject = getObjectProperties(node.arguments[0]);

      if (stylesObject == null) {
        return;
      }

      for (const styleProperty of stylesObject) {
        const styleName = getPropertyName(styleProperty.name) ?? '<computed>';
        const styleObject = getObjectProperties(styleProperty.initializer);

        if (styleObject == null) {
          continue;
        }

        const styleKeys = new Set();
        let fontFamilyExpression = null;

        for (const property of styleObject) {
          const propertyName = getPropertyName(property.name);

          if (propertyName == null) {
            continue;
          }

          styleKeys.add(propertyName);

          if (propertyName === 'fontFamily') {
            fontFamilyExpression = property.initializer;
          }
        }

        const hasTextStyle = [...styleKeys].some((key) =>
          textStyleProperties.has(key),
        );

        if (!hasTextStyle) {
          continue;
        }

        if (fontFamilyExpression == null) {
          report(
            styleProperty,
            styleName,
            `text style missing fontFamily: '${expectedFontFamily}'`,
          );
          continue;
        }

        const fontFamily = resolveFontFamily(fontFamilyExpression, bindings);

        if (fontFamily !== expectedFontFamily) {
          report(
            styleProperty,
            styleName,
            `fontFamily resolves to ${fontFamily ?? 'unknown'}, expected '${expectedFontFamily}'`,
          );
        }
      }
    }

    ts.forEachChild(node, visit);
  }

  visit(sourceFile);
  return issues;
}

const sourceRoots = process.argv.slice(2);
const files = collectSourceFiles(
  sourceRoots.length > 0 ? sourceRoots : defaultRoots,
);
const issues = files.flatMap(findFontFamilyIssues);

if (issues.length === 0) {
  console.log(`Inter fontFamily check passed across ${files.length} files.`);
  process.exit(0);
}

console.error(
  `Inter fontFamily check failed: ${issues.length} style${issues.length === 1 ? '' : 's'} need fontFamily: '${expectedFontFamily}'.`,
);

for (const issue of issues) {
  console.error(
    `${issue.file}:${issue.line}:${issue.column} ${issue.styleName} - ${issue.message}`,
  );
}

process.exit(1);
