import pytest
import testinfra


def test_user_created(host):
    user = host.user('testuser')
    assert user.exists


def test_hostname_set(host):
    hostname = host.check_output('hostname')
    assert hostname
