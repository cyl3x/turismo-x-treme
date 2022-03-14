var thread
var mutex
var sem

var time_max = 100 # Milliseconds.

var queue_new_game = []
var queue_players = {}
var queue_update = []

var http_client = HTTPClient.new()
var status = false

var remote_id

func _lock():
	mutex.lock()

func _unlock():
	mutex.unlock()

func _post():
	sem.post()

func _wait():
	sem.wait()

func request_new_game(headers, query):
	_lock()
	
	queue_new_game.append({
		"method": HTTPClient.METHOD_POST,
		"path": "/api/new/run",
		"headers": headers,
		"query": query,
	})
	
	_unlock()
	_post()
	return

func request_update(net_id, type : String, headers, query):
	_lock()
	
	queue_players[net_id] = {
		"method": HTTPClient.METHOD_PUT,
		"path": "/api/update/player/" + str(remote_id) + "/" + str(net_id) + "/",
		"headers": headers,
		type: query,
	}
	
	if not {"id": net_id, "type": type} in queue_update:
		queue_update.append({"id": net_id, "type": type})
	
	_unlock()
	_post()
	return

func thread_process():
	_wait()
	
	status = false

	while queue_new_game.size() > 0:
		_lock()
		var res = queue_new_game[0]
		_unlock()
		
		while not status:
			_request(res, true)
			
		_lock()
		queue_new_game.erase(res)
		_unlock()
		
		print("History: New game successfully created")
		
	status = false

	while queue_update.size() > 0 and queue_new_game.size() == 0:
		_lock()
		var update = queue_update[0]
		_unlock()
		
		var data = queue_players[update.id].duplicate()
		data["query"] = data[update.type]
		data.path += update.type
		print("History: Update " + str(update) + " with " + str(data))
		
		_request(data)

		_lock()
		queue_update.erase(update)
		_unlock()

func _request(res, new_game = false):
	http_client.connect_to_host("tunier.cyl3x.de", 443, true, true)
	while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		http_client.poll()
		OS.delay_msec(100)
	
	http_client.request(res.method, res.path, res.headers, res.query)
	
	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		http_client.poll()
		OS.delay_msec(100)
		
	status = http_client.get_status() == HTTPClient.STATUS_BODY or http_client.get_status() == HTTPClient.STATUS_CONNECTED
	
	var rb = PoolByteArray()
	while new_game and http_client.get_status() == HTTPClient.STATUS_BODY:
		http_client.poll()
		var chunk = http_client.read_response_body_chunk()
		if chunk.size() != 0:
			rb = rb + chunk
		else:
			OS.delay_msec(100)

	if new_game:
		remote_id = int(JSON.parse(rb.get_string_from_ascii()).result.data)
		print(remote_id)

func thread_func(_u):
	while true:
		thread_process()

func _exit_tree():
	thread.wait_to_finish()

func start():
	mutex = Mutex.new()
	sem = Semaphore.new()
	thread = Thread.new()
	thread.start(self, "thread_func", 0)
