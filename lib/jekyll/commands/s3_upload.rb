require 'active_support/all'

module Jekyll
  module Commands
    class S3Upload < Command
      class << self
        def init_with_program(prog)
          prog.command(:upload) do |c|
            c.syntax      'upload [options]'
            c.description 'Upload the site to the S3 bucket.'
            c.option 'environment', '--environment ENVIRONMENT', 'The environment to upload to.'

            c.action do |args, options|
              Jekyll::Commands::S3Upload.process(options)
            end
          end
        end

        def process(options)
          unless options.key?('environment')
            Jekyll.logger.error 'No environment specified.'
            Jekyll.logger.error 'See `jekyll help upload` for instructions on how to set the upload environment.'
            return false
          end

          jekyll_config = Jekyll.configuration('full_rebuild' => true)

          unless jekyll_config.key?('jekyll-s3-upload')
            Jekyll.logger.error 'jekyll-s3-upload configuration not found in Jekyll config.'
            Jekyll.logger.error 'See README for instructions on how to configure jekyll-s3-upload.'
            return false
          end

          s3_upload_config = jekyll_config.fetch('jekyll-s3-upload')

          require 'dotenv'
          Dotenv.load('.env', ".env.#{options.fetch('environment')}")

          aws_access_key_id, aws_secret_access_key, aws_region, s3_bucket = ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], ENV['AWS_REGION'], ENV['S3_BUCKET']

          unless aws_access_key_id && aws_secret_access_key && s3_bucket
            Jekyll.logger.error 'AWS ENV variables not configured correctly.'
            Jekyll.logger.error 'See README for instructions on how to configure AWS ENV variables.'
            return false
          end

          site = Jekyll::Site.new(jekyll_config)

          if s3_upload_config.fetch('build_before', true)
            Jekyll.logger.info 'Rebuilding before upload...'
            Jekyll::Commands::Build.build(site, jekyll_config)
          end

          if upload_validations = s3_upload_config.fetch('validate_upload', nil)
            Jekyll.logger.info 'Validating Upload...'
            upload_validations.each do |validation_class_name|
              Jekyll.logger.info "Running Upload Validation #{validation_class_name}"
              validation_class = validation_class_name.constantize
              valid = validation_class.validate(jekyll_config, site, Jekyll.logger)
              next if valid

              Jekyll.logger.error "Upload Validation #{validation_class_name} failed. Halting upload."
              return false
            end
            Jekyll.logger.info 'All Upload Validations passed.'
          end

          require 'jekyll/s3/upload/s3_website_uploader'
          require 'jekyll/s3/upload/uploader_file_config_strategy'

          Jekyll.logger.info 'Uploading site...'
          uploader = Jekyll::S3::Upload::S3WebsiteUploader.new({
            aws_access_key_id: aws_access_key_id,
            aws_secret_access_key: aws_secret_access_key,
            aws_region: aws_region,
            s3_bucket: s3_bucket,
            s3_prefix_path: s3_upload_config.fetch('prefix_path', ''),
            build_directory: jekyll_config.fetch('destination'),
            file_strategy: Jekyll::S3::Upload::UploaderFileConfigStrategy.new(s3_upload_config),
            logger: ActiveSupport::TaggedLogging.new(Jekyll.logger.writer)
          })

          return uploader.upload!
        end
      end
    end
  end
end
