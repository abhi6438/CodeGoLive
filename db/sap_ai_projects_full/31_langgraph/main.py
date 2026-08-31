"""
Project: SAP GenAI Hub Integration Series
Topic:   31_langgraph
Goal:    Stateful procurement approval graph: DRAFT->AI_REVIEW->MANAGER_DECISION->APPROVED/REJECTED
Requirements: pip install langgraph langchain-openai
"""

from typing import TypedDict, Literal
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

class ProcurementState(TypedDict):
    pr_number: str
    vendor: str
    amount: float
    description: str
    ai_recommendation: str
    ai_score: int
    manager_decision: str
    status: str
    reason: str


def draft_node(state: ProcurementState) -> ProcurementState:
    print(f"[DRAFT] PR {state['pr_number']} submitted: {state['vendor']} ${state['amount']:,.2f}")
    return {**state, "status": "AI_REVIEW"}


def ai_review_node(state: ProcurementState) -> ProcurementState:
    print(f"[AI_REVIEW] Analyzing PR {state['pr_number']}...")
    prompt = f"""Review this SAP Purchase Requisition:
Vendor: {state['vendor']}
Amount: ${state['amount']:,.2f}
Description: {state['description']}

Respond with:
SCORE: <1-10>
RECOMMENDATION: APPROVE or REJECT
REASON: <one sentence>"""

    response = llm.invoke([SystemMessage(content="You are an SAP procurement AI reviewer."),
                           HumanMessage(content=prompt)])
    text = response.content
    score = 7
    recommendation = "APPROVE"
    reason = "Standard procurement request within policy limits."
    for line in text.split("\n"):
        if line.startswith("SCORE:"):
            try:
                score = int(line.split(":")[1].strip())
            except ValueError:
                pass
        elif line.startswith("RECOMMENDATION:"):
            recommendation = "APPROVE" if "APPROVE" in line else "REJECT"
        elif line.startswith("REASON:"):
            reason = line.split(":", 1)[1].strip()

    print(f"  AI Score: {score}/10, Recommendation: {recommendation}")
    return {**state, "ai_score": score, "ai_recommendation": recommendation, "reason": reason, "status": "MANAGER_DECISION"}


def manager_decision_node(state: ProcurementState) -> ProcurementState:
    print(f"[MANAGER] Reviewing AI recommendation: {state['ai_recommendation']} (score {state['ai_score']})")
    decision = "APPROVED" if state["ai_score"] >= 6 and state["amount"] <= 50000 else "REJECTED"
    print(f"  Manager decision: {decision}")
    return {**state, "manager_decision": decision, "status": decision}


def route_after_manager(state: ProcurementState) -> Literal["approved", "rejected"]:
    return "approved" if state["manager_decision"] == "APPROVED" else "rejected"


def approved_node(state: ProcurementState) -> ProcurementState:
    print(f"[APPROVED] PR {state['pr_number']} approved. Creating PO in SAP MM...")
    return {**state, "status": "APPROVED"}


def rejected_node(state: ProcurementState) -> ProcurementState:
    print(f"[REJECTED] PR {state['pr_number']} rejected. Notifying requester...")
    return {**state, "status": "REJECTED"}


def build_graph():
    graph = StateGraph(ProcurementState)
    graph.add_node("draft", draft_node)
    graph.add_node("ai_review", ai_review_node)
    graph.add_node("manager_decision", manager_decision_node)
    graph.add_node("approved", approved_node)
    graph.add_node("rejected", rejected_node)

    graph.set_entry_point("draft")
    graph.add_edge("draft", "ai_review")
    graph.add_edge("ai_review", "manager_decision")
    graph.add_conditional_edges("manager_decision", route_after_manager,
                                {"approved": "approved", "rejected": "rejected"})
    graph.add_edge("approved", END)
    graph.add_edge("rejected", END)
    return graph.compile()


if __name__ == "__main__":
    app = build_graph()
    initial_state: ProcurementState = {
        "pr_number": "PR-2024-00123",
        "vendor": "SAP SE",
        "amount": 32000.00,
        "description": "Annual SAP S/4HANA cloud subscription renewal",
        "ai_recommendation": "", "ai_score": 0,
        "manager_decision": "", "status": "DRAFT", "reason": "",
    }
    final_state = app.invoke(initial_state)
    print(f"\nFinal Status: {final_state['status']}")
