 # frozen_string_literal: true

require "rbconfig"
require "tmpdir"

module Singed
  module Speedscope
    # Take latest version from https://github.com/jlfwong/speedscope/releases
    # that have ZIP archive with self-contained version published
    VERSION = "1.24.0"

    class << self
      def bundled_index_html
        File.join(File.expand_path("../..", __dir__), "vendor", "speedscope", "index.html")
      end

      def open_command(profile_path)
        if File.exist?(bundled_index_html)
          "#{os_open_command} file://#{bundled_index_html}#localProfilePath=#{profile_path}"
        else
          "npx speedscope #{profile_path}"
        end
      end

      def open(profile_path)
        profile_path = profile_path.to_s

        if File.exist?(bundled_index_html)
          open_with_bundled_speedscope(profile_path)
        else
          open_with_npx(profile_path)
        end
      end

      private

      def open_with_npx(profile_path)
        system("npx", "speedscope", profile_path)
      end

      # Based on speedscope CLI code (MIT license)
      # See https://github.com/jlfwong/speedscope/blob/3613918de0dd55a263d0d04f85b0c8c2039c7bee/bin/cli.mjs
      def open_with_bundled_speedscope(profile_path)
        source_buffer = File.binread(profile_path)
        filename = File.basename(profile_path)

        source_base64 = [source_buffer].pack("m0")
        js_source = "speedscope.loadFileFromBase64(#{filename.inspect}, #{source_base64.inspect})"

        file_prefix = "speedscope-#{Time.now.to_i}-#{Process.pid}"
        js_path = File.join(Dir.tmpdir, "#{file_prefix}.js")
        File.write(js_path, js_source)

        url_to_open = "file://#{File.expand_path(bundled_index_html)}#localProfilePath=#{js_path}"

        # See https://github.com/jlfwong/speedscope/blob/3613918de0dd55a263d0d04f85b0c8c2039c7bee/bin/cli.mjs#L96-L105
        host_os = RbConfig::CONFIG["host_os"]
        if host_os =~ /mswin|mingw|cygwin/ || host_os =~ /darwin/
          html_path = File.join(Dir.tmpdir, "#{file_prefix}.html")
          File.write(html_path, "<script>window.location=#{url_to_open.inspect}</script>")
          url_to_open = "file://#{html_path}"
        end

        system os_open_command, url_to_open
      end

      def os_open_command
        case host_os = RbConfig::CONFIG["host_os"]
        when /mswin|mingw|cygwin/
          "start"
        when /darwin/
          "open"
        when /linux|bsd/
          "xdg-open"
        else
          raise "Unsupported OS to open browser: #{host_os}"
        end
      end
    end
  end
end
