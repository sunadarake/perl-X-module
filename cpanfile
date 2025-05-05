requires 'perl', '5.040';
requires 'Log::Log4perl';
requires 'Moo';
requires 'Selenium::Remote::Driver';
requires 'Selenium::Chrome';
requires 'Teng';
requires "DBI";
requires "DBD::SQLite";
requires "Time::HiRes";
requires "utf8::all";
requires "Net::SSLeay";
requires "IO::Socket::SSL";

on build => sub {
    requires 'Test::More', '0.98';
};