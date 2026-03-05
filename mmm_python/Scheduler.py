import signal
import asyncio
import threading
import time

class Scheduler:
    """The main Scheduler class for the Python side of MMMAudio. Can be used to run asyncio coroutines in a separate scheduling thread. This has the advantage of not blocking the main thread, but also allows for each schedule to be cancelled individually."""

    def __init__(self):
        """Initialize the Scheduler. Also starts the asyncio event loop in its own unique thread."""
        self.loop = None
        self.thread = None
        self.running = False
        self.routines = []

        signal.signal(signal.SIGINT, self._signal_handler)

        self.start_thread()

    def _signal_handler(self, signum, frame):
        """Handle Ctrl+C signal"""
        print("\nReceived Ctrl+C, stopping routines...")
        self.stop_routs()

    async def tc_sleep(self, delay, result=None):
        """Coroutine that completes after a given time (in seconds).
        
        Args:
            delay: Time in seconds to wait before completing the coroutine.
            result: Optional result to return when the coroutine completes.

        """
        if delay <= 0:
            await asyncio.tasks.__sleep0()
            return result

        delay *= self.wait_mult  # Adjust delay based on tempo
        loop = asyncio.events.get_running_loop()
        future = loop.create_future()
        h = loop.call_later(delay,
                            asyncio.futures._set_result_unless_cancelled,
                            future, result)
        try:
            return await future
        finally:
            h.cancel()

    def start_thread(self):
        """Create a new asyncio event loop and run it in a separate scheduling thread."""
        def run_event_loop():
            self.loop = asyncio.new_event_loop()
            asyncio.set_event_loop(self.loop)
            self.running = True
            print(f"Asyncio thread started: {threading.get_ident()}")
            
            try:
                self.loop.run_forever()
            finally:
                self.loop.close()
                self.running = False
                print(f"Asyncio thread stopped: {threading.get_ident()}")
        
        if self.thread is not None and self.thread.is_alive():
            return self.thread

        self.thread = threading.Thread(target=run_event_loop, daemon=False)

        self.thread.start()
        
        # Wait for the loop to be ready
        while not self.running:
            time.sleep(0.01)

        return self.thread
    
    def sched(self, coro):
        """Add a coroutine to the running event loop.

        Args:
            coro: The coroutine to be scheduled.
        
        Returns:
            The Future object representing the scheduled coroutine. This returned object can be used to check the status of the coroutine, retrieve its result, or stop the coroutine when needed.
        """

        # any time a new event is scheduled, clear the routs list of finished coroutines

        for i in range(len(self.routines)-1,-1,-1):
            if self.routines[i].done():
                del self.routines[i]

        if not self.running or not self.loop:
            raise RuntimeError("Asyncio thread is not running")
        
        rout = asyncio.run_coroutine_threadsafe(coro, self.loop)
        self.routines.append(rout)

        return rout

    def stop_routs(self):
        """Stop all running routines."""
        for rout in self.routines:
            rout.cancel()
        self.routines.clear()

    def get_routs(self):
        """Get all running routine."""
        return self.routines

    def stop_thread(self):
        """Stop the asyncio event loop and thread and start a new one."""
        if self.loop and self.running:
            self.loop.call_soon_threadsafe(self.loop.stop)
            if self.thread:
                self.thread.join(timeout=5)
        self.start_thread()