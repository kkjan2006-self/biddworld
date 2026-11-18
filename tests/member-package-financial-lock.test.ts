import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), 'src/components/Packages.tsx'), 'utf8');

describe('member package activation feature gate', () => {
  it('fails closed until the database explicitly enables package activation', () => {
    expect(source).toContain("useState(false)");
    expect(source).toContain(".eq('setting_key','package_activations_enabled')");
    expect(source).toContain("setActivationEnabled(!activationSettingError&&activationSetting?.setting_value===true)");
    expect(source).toContain('{!activationEnabled &&');
    expect(source).toContain('Package activation is temporarily locked.');
    expect(source).toContain('Payment references, activation requests and wallet credits are unavailable while this feature remains disabled.');
  });

  it('renders the activation workflow only after the setting is confirmed enabled', () => {
    expect(source).toContain('{activationEnabled&&<section className="packageActivationForm">');
    expect(source).toContain('submit_package_activation_with_receipt');
    expect(source).toContain("supabase.storage.from('package-receipts').upload");
    expect(source).toContain('A receipt is optional.');
  });

  it('clearly labels displayed wallet credits as proposed and not issued', () => {
    expect(source).toContain('Proposed Bid Wallet credit (not issued)');
    expect(source).toContain('View-only information. Package payments and activation are currently unavailable.');
  });

  it('keeps free registration available while paid activation is unavailable', () => {
    expect(source).toContain('Free member registration is available');
  });
});
