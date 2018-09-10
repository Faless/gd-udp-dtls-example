extends Control

const PORT = 4433
const ADDR = "127.0.0.1"
var dtls = true
var secure = PacketPeerDTLS.new()
var udp = PacketPeerUDP.new()

func _log(msg):
	print(msg)
	$H/log.text += str(msg) + "\n"

func _process(delta):
	if not udp.is_connected_to_host():
		return
	var conn = udp
	if dtls:
		conn = secure
		conn.poll()
		if conn.get_status() != PacketPeerDTLS.STATUS_CONNECTED:
			return
	while conn.get_available_packet_count() > 0:
		var pkt = conn.get_packet()
		_log("Got %s from server" % pkt.get_string_from_utf8())

func _on_connect_pressed():
	_log("Connect to %s %d: %d" % [ADDR, PORT, udp.connect_to_host(ADDR, PORT)])
	print(udp.get_available_packet_count())
	print(udp.put_packet(PoolByteArray()))
	print(udp.get_available_packet_count())
	if dtls:
		secure.blocking_handshake = false
		secure.connect_to_peer(udp)

func _on_send_pressed():
	if dtls:
		secure.put_packet($H/tools/text.text.to_utf8())
	else:
		udp.put_packet($H/tools/text.text.to_utf8())
	$H/tools/text.text = ""