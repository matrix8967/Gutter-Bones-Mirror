import os
import pytest


def test_ctrld_binary_present(host):
    f = host.file('/usr/local/bin/ctrld')
    assert f.exists
    assert f.mode & 0o111


def test_ctrld_service_running_and_enabled(host):
    s = host.service('ctrld')
    assert s.is_running
    assert s.is_enabled


def test_ctrld_listen_port(host):
    # ctrld default from template uses 5354
    sockets = host.socket.get_listening_sockets()
    ports = [s.local_address[1] for s in sockets if s.local_address and len(s.local_address) > 1]
    assert 5354 in ports
