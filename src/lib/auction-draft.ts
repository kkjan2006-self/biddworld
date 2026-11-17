export type AuctionDraftInput = {
  productId: string;
  title: string;
  startingPrice: string;
  minimumIncrement: string;
  startsAt: string;
  endsAt: string;
};

/** Return a user-facing validation message, or an empty string when valid. */
export function validateAuctionDraftInput(input: AuctionDraftInput): string {
  if (!input.productId) return 'Create and select a draft product first.';
  const titleLength = input.title.trim().length;
  if (titleLength < 3 || titleLength > 180) {
    return 'Auction title must be between 3 and 180 characters.';
  }
  const startingPrice = Number(input.startingPrice);
  const minimumIncrement = Number(input.minimumIncrement);
  if (!Number.isFinite(startingPrice) || startingPrice < 0 ||
      !Number.isFinite(minimumIncrement) || minimumIncrement <= 0) {
    return 'Starting price must be zero or more and minimum increment must be greater than zero.';
  }
  const startsAt = input.startsAt ? Date.parse(input.startsAt) : null;
  const endsAt = input.endsAt ? Date.parse(input.endsAt) : null;
  if ((input.startsAt && startsAt === null) || (input.endsAt && endsAt === null) ||
      (input.startsAt && !Number.isFinite(startsAt)) ||
      (input.endsAt && !Number.isFinite(endsAt))) {
    return 'Enter valid auction start and end dates.';
  }
  if (startsAt !== null && endsAt !== null && endsAt <= startsAt) {
    return 'Auction end time must be after its start time.';
  }
  return '';
}
