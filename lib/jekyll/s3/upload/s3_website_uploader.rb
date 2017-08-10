require 'rack'
require 'aws-sdk'

module Jekyll
  module S3
    module Upload
      class S3WebsiteUploader
        def initialize(options)
          @aws_access_key_id = options.fetch(:aws_access_key_id)
          @aws_secret_access_key = options.fetch(:aws_secret_access_key)
          @aws_region = options.fetch(:aws_region)
          @s3_bucket = options.fetch(:s3_bucket)
          @s3_prefix_path = options.fetch(:s3_prefix_path)
          @s3_index_path = options.fetch(:s3_index_path)
          @s3_error_path = options.fetch(:s3_error_path)
          @s3_routing_rules_path = options.fetch(:s3_routing_rules_path)
          @build_directory = options.fetch(:build_directory)
          @file_strategy = options.fetch(:file_strategy)
          @logger = options.fetch(:logger)
        end

        def upload!
          start = Time.now.utc
          logger.info "Upload to #{s3_bucket} started at: #{start.iso8601}"

          s3 = Aws::S3::Client.new({
            region: aws_region,
            access_key_id: aws_access_key_id,
            secret_access_key: aws_secret_access_key
          })

          update_website_configuration!(s3)
          upload_built_files!(s3, start)

          logger.info "Upload complete!"
          logger.info "Time Elapsed: #{Time.now.utc - start} seconds"
          return true
        end

        private

        attr_reader :aws_access_key_id, :aws_secret_access_key, :aws_region,
          :build_directory, :file_strategy, :logger, :s3_bucket,
          :s3_prefix_path, :s3_routing_rules_path, :s3_error_path, :s3_index_path

        def update_website_configuration!(s3)
          if s3_routing_rules_path
            routing_rules = YAML.load_file(s3_routing_rules_path)
          else
            routing_rules = nil
          end

          s3.put_bucket_website(
            bucket: s3_bucket,
            website_configuration: {
              error_document: {
                key: s3_error_path
              }, index_document: {
                suffix: s3_index_path
              },
              routing_rules: routing_rules
            }
          )
        end

        def upload_built_files!(s3, upload_timestamp)
          build_dir_pathame = Pathname.new(build_directory)

          Dir["#{build_directory}/**/*"].each do |file|
            next unless File.file?(file)

            file_pathname = Pathname.new(file)
            file_path_relative_to_build_directory = file_pathname.relative_path_from(build_dir_pathame).to_s

            key = if s3_prefix_path.empty?
                    file_path_relative_to_build_directory
                  else
                    File.join(s3_prefix_path, file_path_relative_to_build_directory)
                  end
            options = {
              acl: 'public-read',
              body: File.open(file),
              bucket: s3_bucket,
              key: key
            }

            options[:content_type] = Rack::Mime.mime_type(File.extname(file))

            if options[:content_type].include?('html')
              redirect_to = extract_redirect_location(file_path_relative_to_build_directory)
              options[:website_redirect_location] = redirect_to if redirect_to
            end

            file_strategy.add_extra_config_for_file(options, file_path_relative_to_build_directory, file)

            s3.put_object(options)
            logger.tagged(options[:key], 'Uploaded') do
              options_description = options.except(:bucket, :key, :body).map do |key, value|
                "#{key}=\"#{value}\""
              end.join(" ")
              logger.info options_description
            end
          end
        end

        def extract_redirect_location(file_path_relative_to_build_directory)
        end

      end
    end
  end
end
