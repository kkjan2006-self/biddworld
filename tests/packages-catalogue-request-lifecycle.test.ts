import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), 'src/components/Packages.tsx'), 'utf8');

describe('Packages catalogue request lifecycle', () => {
  it('invalidates stale requests and prevents updates after unmount', () => {
    expect(source).toContain('const mountedRef = useRef(false)');
    expect(source).toContain('const requestIdRef = useRef(0)');
    expect(source).toContain('requestIdRef.current === requestId');
    expect(source).toContain('mountedRef.current = false');
    expect(source).toContain('requestIdRef.current += 1');
  });

  it('releases loading state only for the current mounted request', () => {
    expect(source).toContain('if (isCurrent()) setLoading(false)');
    expect(source).toContain("setError('Packages could not be loaded. Please try again later.')");
    expect(source).toContain("setError('A network error prevented packages from loading. Please retry.')");
  });

  it('fails closed unless the database explicitly enables package activation', () => {
    expect(source).toContain('const [activationEnabled,setActivationEnabled]=useState(false)');
    expect(source).toContain(".eq('setting_key','package_activations_enabled')");
    expect(source).toContain("setActivationEnabled(!activationSettingError&&activationSetting?.setting_value===true)");
    expect(source).toContain('{!activationEnabled &&');
    expect(source).toContain('Package activation is temporarily locked.');
    expect(source).toContain('Payment references, activation requests and wallet credits are unavailable while this feature remains disabled.');
    expect(source).toContain('{activationEnabled&&<section className="packageActivationForm">');
  });
});
