"""
Project: SAP GenAI Hub Integration Series
Topic:   30_langchain
Goal:    Use LangChain with GenAI Hub: simple chain, memory chat, LCEL pipeline
Requirements: pip install langchain langchain-openai
"""

from langchain_openai import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate

def demo_simple_chain():
    print("=== 1. Simple Chain with StrOutputParser ===")
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are an SAP expert. Answer concisely."),
        ("human", "{question}"),
    ])
    chain = prompt | llm | StrOutputParser()
    result = chain.invoke({"question": "What does transaction MM60 do in SAP?"})
    print(result)


def demo_memory_chat():
    print("\n=== 2. ConversationBufferMemory Chat ===")
    memory = ConversationBufferMemory()
    conversation = ConversationChain(llm=llm, memory=memory, verbose=False)

    turns = [
        "What is SAP S/4HANA?",
        "What are its main modules?",
        "Which module handles procurement?",
    ]
    for turn in turns:
        print(f"User: {turn}")
        response = conversation.predict(input=turn)
        print(f"Bot:  {response[:120]}...\n")


def demo_lcel_expense_pipeline():
    print("=== 3. LCEL Pipeline for SAP Expense Summarization ===")

    expense_data = """
    Expenses for Cost Center CC1000, Q3 2024:
    - Travel: $12,400 (flights, hotels, ground transport)
    - Software Licenses: $45,000 (SAP licenses, cloud subscriptions)
    - Office Supplies: $2,300
    - Training: $8,700 (SAP certification courses)
    - Meals & Entertainment: $3,200
    Total: $71,600
    """

    extract_prompt = ChatPromptTemplate.from_messages([
        ("system", "Extract key financial metrics from SAP expense data. Return bullet points."),
        ("human", "Expense data:\n{data}"),
    ])

    insight_prompt = ChatPromptTemplate.from_messages([
        ("system", "You are a CFO. Give 2-3 cost optimization recommendations based on expense summary."),
        ("human", "Summary:\n{summary}"),
    ])

    extract_chain = extract_prompt | llm | StrOutputParser()
    insight_chain = insight_prompt | llm | StrOutputParser()

    summary = extract_chain.invoke({"data": expense_data})
    print("Summary:\n", summary)

    insights = insight_chain.invoke({"summary": summary})
    print("\nCFO Insights:\n", insights)


if __name__ == "__main__":
    demo_simple_chain()
    demo_memory_chat()
    demo_lcel_expense_pipeline()
