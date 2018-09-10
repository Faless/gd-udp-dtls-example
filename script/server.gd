extends Control

var udp = PacketPeerUDP.new()
var clients = {}
var dtls = true
const PORT = 4433
const ADDR = "127.0.0.1"

func _log(msg):
	print(msg)
	$H/logs.text += str(msg) + "\n"

func _process(delta):
	while udp.get_available_packet_count() > 0:
		_take_connection()

	var to_rem = []
	for k in clients:
		if not _poll_client(clients[k]):
			to_rem.append(k)
	for k in to_rem:
		clients.erase(k)

func _take_connection():
	var pkt = udp.get_packet()
	var addr = udp.get_packet_ip()
	var port = udp.get_packet_port()
	var key = "%s:%d" % [addr, port]
	if not (key in clients):
		_log("Taking connection: %s" % key)
		var conn = udp.take_connection()
		if dtls:
			var secure = PacketPeerDTLS.new()
			secure.blocking_handshake = false
			secure.accept_peer(conn, "res://cert/srv.crt", "res://cert/key.pem")
			print("Handshaking with client")
			conn = secure
		clients[key] = conn

func _poll_client(c):
	if dtls:
		c.poll()
		var status = c.get_status()
		if status != PacketPeerDTLS.STATUS_CONNECTED and status != PacketPeerDTLS.STATUS_HANDSHAKING:
			return false
		if status == PacketPeerDTLS.STATUS_HANDSHAKING:
			return true
	while c.get_available_packet_count() > 0:
		var pkt = c.get_packet()
		if dtls:
			_log("Got %s" % [pkt.get_string_from_utf8()])
		else:
			var addr = c.get_packet_ip()
			var port = c.get_packet_port()
			var key = "%s:%d" % [addr, port]
			_log("Got %s from %s %s" % [pkt.get_string_from_utf8(), addr, port])
		c.put_packet(pkt)
	return true;

func _on_Host_pressed():
	_log("Listen " + str(udp.listen(PORT)))