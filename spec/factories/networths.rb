FactoryBot.define do
  factory :networth, class: 'Ledger::Networth' do
    date { Date.today.to_s }
    invested { '+10.00' }
    investment { '+20.00' }
    amount { '+25.00' }
    currency { 'USD' }

    after(:build) do |networth, _evaluator|
      %w[invested investment amount].each do |field|
        value = networth.public_send(field)

        next if value.nil? || (value.is_a?(String) && value.start_with?(/-|\+/))

        value = value.to_s
        networth.public_send(:"#{field}=", value.start_with?('-') ? value : "+#{value}")
      end
    end
  end
end
