# frozen_string_literal: true

require 'logging'

# Avatax tax calculation API calls
class TaxSvc
  def get_tax(request_hash)
    log(__method__, request_hash)

    req = client.transactions.create_or_adjust(request_hash)

    response = SolidusAvataxCertified::Response::GetTax.new(req)

    handle_response(response)
  end

  def cancel_tax(transaction_code)
    log(__method__, transaction_code)

    req = client.transactions.void(company_code, transaction_code)
    response = SolidusAvataxCertified::Response::CancelTax.new(req)

    handle_response(response)
  end

  def ping
    logger.info 'Ping Call'

    # Testing if configuration is set up properly, ping will fail if it is not
    client.tax_rates.get(:by_postal_code, country: 'US', postalCode: '07801')
  end

  def validate_address(address)
    begin
      request = client.addresses.validate(address)
    rescue StandardError => e
      logger.error(e)

      request = { 'error' => { 'message' => e } }
    end

    response = SolidusAvataxCertified::Response::AddressValidation.new(request)
    handle_response(response)
  end

  protected

  def handle_response(response)
    result = response.result
    begin
      if response.error?
        raise SolidusAvataxCertified::RequestError, result
      end

      logger.debug(result, response.description + ' Response')
    rescue SolidusAvataxCertified::RequestError => e
      logger.error(e.message, response.description + ' Error')
      raise if raise_exceptions?
    end

    response
  end

  def logger
    @logger ||= SolidusAvataxCertified::AvataxLog.new('TaxSvc class', 'Call to tax service')
  end

  private

  def tax_calculation_enabled?
    SolidusAvataxCertified::Config.tax_calculation
  end

  def account_number
    SolidusAvataxCertified::Config.account
  end

  def license_key
    SolidusAvataxCertified::Config.license_key
  end

  def raise_exceptions?
    SolidusAvataxCertified::Config.raise_exceptions
  end

  def company_code
    SolidusAvataxCertified::Config.company_code
  end

  def environment
    SolidusAvataxCertified::Config.environment
  end

  def client
    @client ||= Avatax::Client.new(
      username: account_number,
      password: license_key,
      env: environment,
      headers: AVATAX_HEADERS
    )
  end

  def log(method, request_hash = nil)
    return if request_hash.nil?

    logger.debug(request_hash, "#{method} request hash")
  end
end
