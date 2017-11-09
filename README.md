# Ledger

Simple and straightforward CLI money tracker

### Instructions

1) Clone the repository

2) Run
```
ledger=`gem build ledger.gemspec | grep "File: " | sed -r 's/\s*File:(.+)/\1/'`
```

3) Run `gem install $ledger`

4) Run `ledger configure` (copy configuration file from `config/default`)

5) Run `ledger create` (create ledger file)

6) Run `ledger`
