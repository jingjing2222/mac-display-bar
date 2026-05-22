import { useState } from 'react';

export const displayTabs = [
  'display',
  'color',
  'arrange',
  'input',
  'advanced',
] as const;

export function useDisplayTabs() {
  const [activeTab, setActiveTab] =
    useState<(typeof displayTabs)[number]>('display');

  return {
    activeTab,
    setActiveTab,
    tabs: displayTabs,
  };
}
