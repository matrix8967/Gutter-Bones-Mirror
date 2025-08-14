#!/usr/bin/env python3
# library/verify_ctrld.py
# Ansible module to download and verify ctrld binaries

from ansible.module_utils.basic import AnsibleModule
import hashlib
import os
import tempfile
import urllib.request

def sha256sum(filename):
    h = hashlib.sha256()
    with open(filename, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()

def download(url, dest):
    urllib.request.urlretrieve(url, dest)

def main():
    module = AnsibleModule(
        argument_spec=dict(
            url=dict(type='str', required=True),
            checksum_url=dict(type='str', required=True),
            dest=dict(type='str', required=True),
        ),
        supports_check_mode=False
    )

    url = module.params['url']
    checksum_url = module.params['checksum_url']
    dest = module.params['dest']

    # Cache file in /tmp
    cache_file = os.path.join(tempfile.gettempdir(), os.path.basename(url))

    try:
        # Download cached binary if not exists
        if not os.path.exists(cache_file):
            download(url, cache_file)

        # Download checksum file
        checksum_file = os.path.join(tempfile.gettempdir(), 'ctrld.sha256')
        download(checksum_url, checksum_file)

        # Parse SHA256 from checksum file
        expected_sha = None
        with open(checksum_file, 'r') as f:
            for line in f:
                if os.path.basename(url) in line:
                    expected_sha = line.split()[0]
                    break

        if not expected_sha:
            module.fail_json(msg=f"SHA256 for {url} not found in checksum file")

        actual_sha = sha256sum(cache_file)
        if actual_sha != expected_sha:
            # Redownload if mismatch
            download(url, cache_file)
            actual_sha = sha256sum(cache_file)
            if actual_sha != expected_sha:
                module.fail_json(msg=f"Checksum mismatch for {url}")

        # Place binary in dest if changed
        changed = False
        if not os.path.exists(dest) or sha256sum(dest) != expected_sha:
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            os.replace(cache_file, dest)
            os.chmod(dest, 0o755)
            changed = True

        module.exit_json(changed=changed, dest=dest, sha256=expected_sha)

    except Exception as e:
        module.fail_json(msg=str(e))

if __name__ == '__main__':
    main()
