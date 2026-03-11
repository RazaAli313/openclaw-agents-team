from openai import OpenAI

# Initialize the client with MiniMax's base URL and your API key
client = OpenAI(
    api_key="", # Replace with your actual key
    base_url="https://api.minimax.io/v1"
)

response = client.chat.completions.create(
    model="MiniMax-M2.5",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Explain the minimax algorithm simply."}
    ],
    # Optional: Enable reasoning to see the model's 'thinking' process
    extra_body={"reasoning_split": True} 
)

# Print the final answer
print(response.choices[0].message.content)
