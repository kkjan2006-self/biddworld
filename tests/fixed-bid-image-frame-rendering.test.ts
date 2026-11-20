import {readFileSync} from 'node:fs';
import {describe,it} from 'node:test';
import assert from 'node:assert/strict';
const styles=readFileSync('src/style.css','utf8');
describe('Fixed Bid product image presentation',()=>{
 it('fills the complete product media frame without distortion',()=>{
  assert.match(styles,/\.fixedBidVisual img\{[^}]*width:100%;[^}]*height:100%;[^}]*object-fit:cover;[^}]*display:block/);
 });
});
