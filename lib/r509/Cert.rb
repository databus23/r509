require 'openssl'
require 'r509/Exceptions'
require 'r509/io_helpers'

module R509
	# The primary certificate object.
	class Cert
    include R509::IOHelpers

		attr_reader :cert, :san_names, :key
		def initialize(*args)
			@san_names = nil
			@extensions = nil
			@cert = nil
			@key = nil
			case args.size
				when 0 then raise ArgumentError, 'Too few args. 1-2 (cert,key)'
				when 1
					parse_certificate(args[0])
				when 2
					parse_certificate(args[0])
					@key = OpenSSL::PKey::RSA.new args[1]
					#we can't use verify here because verify does not do what it does for CSR
					if !(@cert.public_key.to_s == @key.public_key.to_s) then
						raise R509Error, 'Key does not match cert.'
					end
				else
					raise ArgumentError, 'Too many args. Max 2 (cert,key)'
			end
		end

		# Converts the Cert into the PEM format
		#
		# @return [String] the Cert converted into PEM format.
		def to_pem
			if(@cert.kind_of?(OpenSSL::X509::Certificate)) then
				return @cert.to_pem.chomp
			end
		end

		alias :to_s :to_pem

		# Converts the Cert into the DER format
		#
		# @return [String] the Cert converted into DER format.
		def to_der
			if(@cert.kind_of?(OpenSSL::X509::Certificate)) then
				return @cert.to_der
			end
		end

		# Returns beginning (notBefore) of certificate validity period
		#
		# @return [Time] time object
		def not_before
			@cert.not_before
		end

		# Returns ending (notAfter) of certificate validity period
		#
		# @return [Time] time object
		def not_after
			@cert.not_after
		end

		# Returns the certificate public key in PEM format
		#
		# @return [Object] public key object (some kind of OpenSSL thing. Just call .to_pem)
		def public_key
			@cert.public_key
		end

		# Returns the issuer
		#
		# @return [OpenSSL::X509::Name] issuer object. Can be parsed as string easily
		def issuer
			@cert.issuer
		end

		# Returns the subject
		#
		# @return [OpenSSL::X509::Name] subject object. Can be parsed as string easily
		def subject
			@cert.subject
		end

        # Returns subject component
        #
        # @return [String] value of the subject component requested
        def subject_component short_name
            @cert.subject.to_a.each do |element|
                if element[0].downcase == short_name.downcase then
                    return element[1]
                end
            end
            nil
        end

		# Returns the bit strength of the key used to create the certificate
		#
		# @return [Integer] integer value of bit strength
		def bit_strength
			if !@cert.nil?
				#cast to int, convert to binary, count size
				@cert.public_key.n.to_i.to_s(2).size
			end
		end

        # Returns signature algorithm 
        # # 
        # # @return [String] value of the signature algorithm. E.g. sha1WithRSAEncryption, sha256WithRSAEncryption, md5WithRSAEncryption
        def signature_algorithm 
            @cert.signature_algorithm 
        end

        # Returns key algorithm (RSA/DSA)
        # #
        # # @return [String] value of the key algorithm. RSA or DSA
        def key_algorithm
            if @cert.public_key.kind_of? OpenSSL::PKey::RSA then 
                'RSA'
            elsif @cert.public_key.kind_of? OpenSSL::PKey::DSA then
                'DSA'
            else 
                nil
            end
        end

		# Writes the Cert into the PEM format
		# @param [String, #write] filename_or_io Either a string of the path for 
    #  the file that you'd like to write, or an IO-like object.
		def write_pem(filename_or_io)
      write_data(filename_or_io, @cert.to_pem)
		end

		# Writes the Cert into the DER format
		# @param [String, #write] filename_or_io Either a string of the path for 
    #  the file that you'd like to write, or an IO-like object.
		def write_der(filename_or_io)
      write_data(filename_or_io, @cert.to_der)
		end

		# Return the certificate extensions
		#
		# @return [Array] an array of hashes representing the extensions in the cert
		def extensions
			parsed_extensions = Hash.new
			@cert.extensions.to_a.each { |extension| 
				extension = extension.to_a
				if(!parsed_extensions[extension[0]].kind_of?(Array)) then
					parsed_extensions[extension[0]] = []
				end
				hash = {'value' => extension[1], 'critical' => extension[2]}
				parsed_extensions[extension[0]].push hash
			}
			parsed_extensions
		end

		private
		#takes OpenSSL::X509::Extension object
		def parse_san_extension(extension)
			san_string = extension.to_a[1]
			stripped = san_string.split(',').map{ |name| name.gsub(/DNS:/,'').strip }
			@san_names = stripped
		end

		def parse_certificate(cert)
			@cert = OpenSSL::X509::Certificate.new cert
			@cert.extensions.to_a.each { |extension| 
				if (extension.to_a[0] == 'subjectAltName') then
					parse_san_extension(extension)
				end
			}
		end

	end
end