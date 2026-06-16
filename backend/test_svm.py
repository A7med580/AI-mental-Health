import asyncio
from services.model_router import ModelRouter

async def test():
    router = ModelRouter()
    res = await router.execute_depression_screening(None, {"depression_q_0_text": "I feel sad"})
    print(res)

asyncio.run(test())
