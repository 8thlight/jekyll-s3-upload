module Jekyll
  module S3
    module Upload
      class UploaderFileConfigStrategy
        def initialize(upload_config)
          @upload_config = upload_config
        end

        def add_extra_config_for_file(s3_file_options, file_path_relative_to_build_directory, absolute_file_path)
          if @upload_config.fetch('reduced_redundancy_storage', false)
            s3_file_options[:storage_class] = 'REDUCED_REDUNDANCY'
          else
            s3_file_options[:storage_class] = 'STANDARD'
          end

          @upload_config.fetch('headers', {}).each do |glob, headers|
            next unless File.fnmatch?(glob, file_path_relative_to_build_directory)

            if headers.key?('cache_control')
              s3_file_options[:cache_control] = headers.fetch('cache_control')
            end

            if headers.key?('expires')
              begin
                expires_seconds_from_now = headers.fetch('expires').to_i
                s3_file_options[:expires] = File.mtime(absolute_file_path) + expires_seconds_from_now
              rescue ArgumentError
                raise 'expires file header must be an integer represeting seconds from now'
              end
            end

            break
          end
        end
      end
    end
  end
end
