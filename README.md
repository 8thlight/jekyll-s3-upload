# jekyll-s3-upload

## Example Usage

Here's an example of usage (excerpted from a Jekyll `_config.yml`):

```yaml
jekyll-s3-upload:
  build_before: true
  reduced_redundancy_storage: true
  prefix_path: 'blog'
  routing_rules_path: 'config/routing_rules.yml'
  website_redirect_config_path: 'config/website_redirects.yml'
  index_path: 'index.html'
  error_path: 'blog/404.html'
  validate_upload:
    - ValidateVersionIsNotSnapshot
  headers:
    "assets/*":
      cache_control: 'public, max-age=2592000' # 30.days.seconds
    "*":
      cache_control: 'public, max-age=300' # 5.minutes.seconds
```
