## `ical_forecast`

Print a forecast of upcoming events from a list of iCal files.

### Installation

`gem install ri_cal tzinfo`

### Usage

	jcs@humble:~> ruby ical_forecast.rb ~/.cals/*.cal
	some far out event in 3 weeks, 6 days (wed 1 sep)
	something here in 1 day (fri 6 aug to sun 8 aug)
	some timed event today at 08:45 (thu 5 aug)

### Related

[remind_forecast](https://github.com/jcs/remind_forecast) which
does the same thing from `remind` or `iCalBuddy`.
