FactoryBot.define do
  factory :networth, class: 'Ledger::Networth' do
    date { Date.today.to_s }
    invested { '10.0' }
    investment { '20.0' }
    amount { '25.0' }
    currency { 'USD' }
  end
end
