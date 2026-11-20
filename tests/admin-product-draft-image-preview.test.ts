import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';

describe('Admin product draft image preview',()=>{
  it('renders the current image URL as an accessible lazy-loaded preview',()=>{
    const source=readFileSync('src/components/Admin.tsx','utf8');
    expect(source).toContain('Product image preview');
    expect(source).toContain('alt={productName.trim()?productName.trim()+\' product preview\':\'Product image preview\'}');
    expect(source).toContain('loading="lazy"');
    expect(source).toContain('onError={e=>{e.currentTarget.style.visibility=\'hidden\';}}');
  });
});
