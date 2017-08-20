# Default values of a transaction
DEFAULT_ACCOUNT_CODE = ENV['LEDGER_DEFAULT_ACCOUNT_CODE'].freeze
DEFAULT_DATE = Date.today.freeze
DEFAULT_CATEGORY = ENV['LEDGER_DEFAULT_CATEGORY'].freeze
DEFAULT_DESCRIPTION = ENV['LEDGER_DEFAULT_DESCRIPTION'].freeze
DEFAULT_AMOUNT = BigDecimal(ENV['LEDGER_DEFAULT_AMOUNT'].to_f.to_s).freeze
DEFAULT_CURRENCY = ENV['LEDGER_DEFAULT_CURRENCY'].freeze
DEFAULT_TRAVEL = ENV['LEDGER_DEFAULT_TRAVEL'].freeze

# Default list of values for auto complete
DEFAULT_CATEGORIES_LIST = ENV['LEDGER_DEFAULT_CATEGORIES_LIST'].to_s.split(',').sort.freeze
DEFAULT_CURRENCIES_LIST = ENV['LEDGER_DEFAULT_CURRENCIES_LIST'].to_s.split(',').sort.freeze

# Default variables to encrypt/decrypt ledger
DEFAULT_SALT = ENV['LEDGER_DEFAULT_SALT'].freeze
DEFAULT_PASSWORD = ENV['LEDGER_DEFAULT_PASSWORD'].freeze

# Define if the ledger file must be encrypted after each operation
# ENCRYPTION = ENV['LEDGER_ENCRYPTION'] == 'true' ? true : false
ENCRYPTION = false
