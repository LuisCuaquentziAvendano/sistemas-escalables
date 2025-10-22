import asyncio
import aiohttp
import sys

async def fetch(session, url, i):
    try:
        async with session.get(url) as response:
            await response.text()
            print(f"Request {i} done (status: {response.status})")
    except Exception as e:
        print(f"Request {i} failed: {e}")

async def run(url, total_requests, concurrency):
    connector = aiohttp.TCPConnector(limit_per_host=concurrency)
    async with aiohttp.ClientSession(connector=connector) as session:
        tasks = []
        for i in range(1, total_requests + 1):
            tasks.append(fetch(session, url, i))
        await asyncio.gather(*tasks)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Invalid arguments")
        sys.exit(1)
    url = sys.argv[1]
    total_requests = int(sys.argv[2])
    concurrency = int(sys.argv[3])
    asyncio.run(run(url, total_requests, concurrency))
    print(f"\nCompleted {total_requests} requests")
