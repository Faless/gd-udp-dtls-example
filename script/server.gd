extends Control

const PORT = 4433
const ADDR = "127.0.0.1"
var _key = preload("res://cert/generated.key")
var _cert = preload("res://cert/generated.crt")

var dtls = true
var clients = {}
var idx = 0
var udp_server = UDPServer.new()
var dtls_server = DTLSServer.new()

func _log(msg):
	print(msg)
	$H/logs.text += str(msg) + "\n"

func _process(delta):
	udp_server.poll()
	if udp_server.is_connection_available():
		# Try to perform DTLS handshake
		_take_connection()

	# Clean stale clients
	var to_rem = []
	for k in clients:
		if not _poll_client(clients[k]):
			to_rem.append(k)
	for k in to_rem:
		clients.erase(k)

func _take_connection():
	var key = str(idx)
	idx += 1
	if not (key in clients):
		_log("Taking connection: %s" % key)
		# Get the UDP connection
		var conn = udp_server.take_connection()
		if dtls:
			# Try to handshake with the UDP peer
			var secure = dtls_server.take_connection(conn)
			if secure.get_status() != PacketPeerDTLS.STATUS_HANDSHAKING:
				idx -= 1
				_log("Handshake failed")
			else:
				# 50% of the time under regular conditions (client connecting with no cookie set)
				_log("Handshaking with client")
				clients[key] = secure
		else:
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
			_log("Got %s from %s %s" % [pkt.get_string_from_utf8(), addr, port])
		c.put_packet(pkt)
	return true

func _on_Host_pressed():
	_log("Setup: %s" % dtls_server.setup(_key, _cert, null))
	_log("Listen " + str(udp_server.listen(PORT)))
