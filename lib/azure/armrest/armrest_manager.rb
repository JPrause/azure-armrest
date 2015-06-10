module Azure
  module ArmRest
    # Abstract base class for the other manager classes.
    class ArmRestManager

      # The subscription ID (billing unit) for your Azure services
      attr_accessor :subscription_id

      # The resource group within the subscription.
      attr_accessor :resource_group

      # The API version of the REST interface. The default is 2015-1-1.
      attr_accessor :api_version

      # Base url used for REST calls.
      attr_accessor :base_url

      # The bearer token set in the constructor.
      attr_accessor :token

      # The content-type use for requests.
      attr_reader :content_type

      # The oauth2 strategy used for gathering the authentication token.
      # The default is 'client_credentials'.
      attr_reader :grant_type

      # Do not instantiate directly. This is an abstract base class from which
      # all other manager classes should subclass, and call super within their
      # own constructors.
      #
      # The possible options to the constructor are:
      #
      # * subscription_id - Your Azure subscription ID. If no subscription
      #     is specifified, then information for all subscriptions will be
      #     collected.
      #
      # * resource_group - The resource group within the subscription. If no
      #     resource group is specified, then information for all resource
      #     groups will be gathered.
      #
      # * client_id - Your Azure client ID. Mandatory.
      #
      # * client_key - The key (secret) for your client ID. Mandatory.
      #
      # * tenant_id - Your Azure tenant ID. Mandatory.
      #
      # * api_version - The REST API version to use for internal REST calls.
      #     The default is '2015-01-01'. You will typically not set this
      #     as it could cause breakage.
      #
      def initialize(options = {})
        # Mandatory params
        @client_id  = options.fetch(:client_id)
        @client_key = options.fetch(:client_key)
        @tenant_id  = options.fetch(:tenant_id)

        # Optional params
        @subscription_id = options[:subscription_id]
        @resource_group  = options[:resource_group]
        @api_version     = options[:api_version] || '2015-01-01'
        @grant_type      = options[:grant_type] || 'client_credentials'

        # The content-type used for all internal http requests
        @content_type = 'application/json'

        # Call the get_token method to set this.
        @token = nil

        # Base URL used for REST calls. Modify within method calls as needed.
        @base_url = Azure::ArmRest::RESOURCE
      end

      # Gets an authentication token, which is then used for all other methods.
      # This will also set the subscription_id to the first subscription found
      # if you did not set it in the constructor.
      #
      # You must call this before calling any other methods.
      #
      def get_token
        token_url = Azure::ArmRest::AUTHORITY + @tenant_id + "/oauth2/token"

        resp = RestClient.post(
          token_url,
          :grant_type    => @grant_type,
          :client_id     => @client_id,
          :client_secret => @client_key,
          :resource      => Azure::ArmRest::RESOURCE
        )

        @token = 'Bearer ' + JSON.parse(resp)['access_token']

        unless @subscription_id
          @subscription_id = subscriptions.first['subscriptionId']
        end

        self
      end

      # Returns a list of subscriptions for the tenant.
      #
      def subscriptions
        url = @base_url + "subscriptions" + "?api-version=#{api_version}"

        resp = rest_get(url)

        JSON.parse(resp.body)["value"]
      end

      # Return information for the specified subscription ID, or the
      # subscription ID that was provided in the constructor if none is
      # specified.
      #
      def subscription_info(subscription_id = @subscription_id)
        url = @base_url + "subscriptions/#{subscription_id}"
        url += "?api-version=#{api_version}"

        resp = rest_get(url)

        JSON.parse(resp.body)
      end

      # Returns a list of resource groups for the given subscription.
      #
      def resource_groups
        url = @base_url + "subscriptions/#{subscription_id}"
        url += "/resourcegroups?api-version=#{api_version}"

        resp = rest_get(url)

        JSON.parse(resp.body)
      end

      # Returns information the specified resource group, or the
      # resource group specified in the constructor if none is provided.
      #
      def resource_group_info(resource_group = @resource_group)
        url = @base_url + "subscriptions/#{subscription_id}"
        url += "/resourcegroups/#{resource_group}?api-version=#{api_version}"

        resp = rest_get(url)

        JSON.parse(resp.body)
      end

      private

      # REST verb methods

      def rest_get(url)
        RestClient.get(
          url,
          :content_type  => @content_type,
          :authorization => @token,
        )
      end

      def rest_put(url)
        RestClient.put(
          url,
          :content_type  => @content_type,
          :authorization => @token,
        )
      end

      def rest_post(url)
        RestClient.post(
          url,
          :content_type  => @content_type,
          :authorization => @token,
        )
      end

      def rest_delete(url)
        RestClient.delete(
          url,
          :content_type  => @content_type,
          :authorization => @token,
        )
      end

    end # ArmRestManager
  end # ArmRest
end # Azure
