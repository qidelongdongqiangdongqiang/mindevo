#!/usr/bin/env python3
"""Set Content-Disposition: inline for objects under assets/images/ in OSS."""
import os
import sys

import oss2


def main():
    access_key_id = os.environ.get("OSS_ACCESS_KEY_ID", "").strip()
    access_key_secret = os.environ.get("OSS_ACCESS_KEY_SECRET", "").strip()
    endpoint = os.environ.get("OSS_ENDPOINT", "").strip()
    bucket_name = os.environ.get("OSS_BUCKET", "").strip()

    if not all([access_key_id, access_key_secret, endpoint, bucket_name]):
        print("Missing OSS environment variables", file=sys.stderr)
        sys.exit(1)

    auth = oss2.Auth(access_key_id, access_key_secret)
    bucket = oss2.Bucket(auth, endpoint, bucket_name)

    prefix = "assets/images/"
    updated = 0
    for obj in oss2.ObjectIterator(bucket, prefix=prefix):
        key = obj.key
        if key == prefix:
            continue
        # Use copy-to-self to update standard headers such as Content-Disposition.
        bucket.copy_object(bucket_name, key, key, headers={"Content-Disposition": "inline"})
        print(f"Set Content-Disposition:inline for {key}")
        updated += 1

    print(f"Updated {updated} objects")


if __name__ == "__main__":
    main()
