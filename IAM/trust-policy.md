# Principle of Least Privilege

The Principle of Least Privilege (PoLP) means granting only the permissions required to perform a specific task.

Examples from this project:

✅ EC2 can communicate with Systems Manager.

❌ EC2 cannot delete S3 buckets.

✅ Lambda can invoke Systems Manager.

❌ Lambda cannot terminate EC2 instances.

Benefits:

- Improved security
- Reduced attack surface
- Better compliance
- Easier auditing
