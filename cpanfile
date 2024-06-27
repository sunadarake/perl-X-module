requires 'Module::Load';
requires 'perl', '5.016';

on build => sub {
    requires 'Test::More', '0.98';
};