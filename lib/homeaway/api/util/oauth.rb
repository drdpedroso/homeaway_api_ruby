# Copyright (c) 2015 HomeAway.com, Inc.
# All rights reserved.  http://www.homeaway.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'oauth2'

module HomeAway
  module API
    module Util
      module OAuth

        # @return [String] the Base64 encoded credentials for the current client
        def credentials
          Base64.strict_encode64 "#{@configuration.client_id}:#{@configuration.client_secret}"
        end

        # @private
        def auth_url
          oauth_client_strategy.authorize_url
        end

        # completes the oauth flow
        # @param code [String] service ticket to authenticate
        # @return [Boolean] true if the authentication succeeded, false otherwise
        def oauth_code=(code)
          begin
            auth_code_strategy = oauth_client_strategy
            token = auth_code_strategy.get_token(code, :headers => {'Authorization' => "Basic #{credentials}"})
            @token = token.token
            @token_expires = Time.at token.expires_at
            @mode = :three_legged
            return true
          rescue => _
            raise HomeAway::API::Errors::UnauthorizedError.new
          end
        end

        private

        def oauth_client
          site = @configuration[:oauth_site] ||= @configuration[:site]
          OAuth2::Client.new(@configuration.client_id,
                             @configuration.client_secret,
                             :site => site,
                             :raise_errors => false
          )
        end

        def oauth_client_strategy
          client = oauth_client
          client.auth_code
        end

        def two_legged!
          begin
            client = oauth_client
            client_credentials_strategy = client.client_credentials
            token = client_credentials_strategy.get_token
            @token = token.token
            @token_expires = Time.at token.expires_at
            @mode = :two_legged
            return true
          rescue => _
            raise HomeAway::API::Errors::UnauthorizedError.new
          end
        end
      end
    end
  end
end