import { FlashList } from '@shopify/flash-list';
import type { FlashListProps } from '@shopify/flash-list';

type FlashListBackedProps<ItemT> = Omit<
  FlashListProps<ItemT>,
  'removeClippedSubviews'
> & {
  estimatedItemSize?: number;
  removeClippedSubviews?: boolean;
};

export function StableLegendList<ItemT>({
  estimatedItemSize: _estimatedItemSize,
  removeClippedSubviews: _removeClippedSubviews,
  ...props
}: FlashListBackedProps<ItemT>) {
  return <FlashList {...props} removeClippedSubviews={false} />;
}
