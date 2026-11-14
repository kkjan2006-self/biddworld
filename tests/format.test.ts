import {describe,it,expect} from 'vitest';
import {money,left} from '../src/lib/format';
describe('format helpers',()=>{it('formats INR currency',()=>expect(money(1250)).toContain('1,250'));it('marks past auctions ended',()=>expect(left('2000-01-01T00:00:00.000Z')).toBe('Ended'));});
