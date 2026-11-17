export type AuctionDraftInput = {
  productId: string;
  title: string;
  startingPrice: string;
  minimumIncrement: string;
  startsAt: string;
  endsAt: string;
};

function parseLocalDateTime(value:string):number|null{
 const match=/^(\\d{4})-(\\d{2})-(\\d{2})T(\\d{2}):(\\d{2})(?::(\\d{2})(?:\\.(\\d{1,3}))?)?$/.exec(value);
 if(!match)return null;
 const [,yearText,monthText,dayText,hourText,minuteText,secondText='0',millisecondText='0']=match;
 const year=Number(yearText),month=Number(monthText),day=Number(dayText),hour=Number(hourText),minute=Number(minuteText),second=Number(secondText),millisecond=Number(millisecondText.padEnd(3,'0'));
 const date=new Date(year,month-1,day,hour,minute,second,millisecond);
 if(date.getFullYear()!==year||date.getMonth()!==month-1||date.getDate()!==day||date.getHours()!==hour||date.getMinutes()!==minute||date.getSeconds()!==second||date.getMilliseconds()!==millisecond)return null;
 return date.getTime();
}

/** Return a user-facing validation message, or an empty string when valid. */
export function validateAuctionDraftInput(input: AuctionDraftInput): string {
  if (!input.productId) return 'Create and select a draft product first.';
  const titleLength = input.title.trim().length;
  if (titleLength < 3 || titleLength > 180) {
    return 'Auction title must be between 3 and 180 characters.';
  }
  const startingPrice = Number(input.startingPrice);
  const minimumIncrement = Number(input.minimumIncrement);
  if (!input.startingPrice.trim() || !Number.isFinite(startingPrice) || startingPrice < 0 ||
      !input.minimumIncrement.trim() || !Number.isFinite(minimumIncrement) || minimumIncrement <= 0) {
    return 'Starting price must be zero or more and minimum increment must be greater than zero.';
  }
  const startsAt = input.startsAt ? parseLocalDateTime(input.startsAt) : null;
  const endsAt = input.endsAt ? parseLocalDateTime(input.endsAt) : null;
  if ((input.startsAt && startsAt === null) || (input.endsAt && endsAt === null)) {
    return 'Enter valid auction start and end dates.';
  }
  if (startsAt !== null && endsAt !== null && endsAt <= startsAt) {
    return 'Auction end time must be after its start time.';
  }
  return '';
}
