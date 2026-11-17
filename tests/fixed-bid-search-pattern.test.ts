import {describe,expect,it} from 'vitest';
import {escapeLikePattern} from '../src/lib/like-pattern';

describe('escapeLikePattern',()=>{
  it('escapes SQL LIKE wildcards so searches match literal text',()=>{
    expect(escapeLikePattern('100%_complete')).toBe('100\\%\\_complete');
  });
  it('escapes existing backslashes before wildcard characters',()=>{
    expect(escapeLikePattern('folder\\name%')).toBe('folder\\\\name\\%');
  });
  it('leaves ordinary search text unchanged',()=>{
    expect(escapeLikePattern('Auction campaign 2026')).toBe('Auction campaign 2026');
  });
});
