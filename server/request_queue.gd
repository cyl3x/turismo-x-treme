var thread
var mutex
var sem

var time_max = 100 # Milliseconds.

var queue = []

var http_client = HTTPClient.new()

func _lock(_caller):
	mutex.lock()


func _unlock(_caller):
	mutex.unlock()

func _post(_caller):
	sem.post()


func _wait(_caller):
	sem.wait()

func request(method, path, headers, query):
	_lock("queue_resource")
	queue.insert(0, {
		"method": method,
		"path": path,
		"headers": headers,
		"query": query,
	})
	_post("queue_resource")
	_unlock("queue_resource")
	return

func request_place(path, headers, query):
	_lock("queue_resource")
	queue.insert(0, {
		"method": HTTPClient.METHOD_PUT,
		"path": path,
		"headers": headers,
		"query": query,
	})
	_post("queue_resource")
	_unlock("queue_resource")
	return

func thread_process():
	_wait("thread_process")
	_lock("process")

	while queue.size() > 0:
		_unlock("process_poll")
		var res = queue[0]
		_lock("process_check_queue")
		
		http_client.connect_to_host("tunier.cyl3x.de", 443, true, true)
		while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
			http_client.poll()
		
		http_client.request(res.method, res.path, res.headers, res.query)
		
		while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
			http_client.poll()
			
		#if http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED

		queue.erase(res)
	_unlock("process")


func thread_func(_u):
	while true:
		thread_process()

# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
	thread.wait_to_finish()

func start():
	mutex = Mutex.new()
	sem = Semaphore.new()
	thread = Thread.new()
	thread.start(self, "thread_func", 0)
