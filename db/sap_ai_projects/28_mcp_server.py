"""
Project: SAP GenAI Hub Integration Series
Topic:   28_mcp_server
Goal:    Build a Python MCP server exposing 3 SAP tools via stdio transport
Requirements: pip install mcp
"""

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent
import json
import asyncio

app = Server("sap-mcp-server")


@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="get_material_stock",
            description="Get stock level for a material at a plant",
            inputSchema={
                "type": "object",
                "properties": {
                    "material": {"type": "string", "description": "Material number"},
                    "plant": {"type": "string", "description": "Plant code"},
                },
                "required": ["material", "plant"],
            },
        ),
        Tool(
            name="get_open_pos",
            description="Get open purchase orders for a company code",
            inputSchema={
                "type": "object",
                "properties": {
                    "company_code": {"type": "string", "description": "SAP company code"},
                },
                "required": ["company_code"],
            },
        ),
        Tool(
            name="get_user_info",
            description="Get SAP user profile information",
            inputSchema={
                "type": "object",
                "properties": {
                    "user_id": {"type": "string", "description": "SAP user ID"},
                },
                "required": ["user_id"],
            },
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "get_material_stock":
        material = arguments["material"]
        plant = arguments["plant"]
        result = {"material": material, "plant": plant, "stock": 1500, "unit": "EA", "status": "available"}

    elif name == "get_open_pos":
        company_code = arguments["company_code"]
        result = {
            "company_code": company_code,
            "open_pos": [
                {"po_number": "4500001234", "vendor": "ACME Corp", "amount": 25000.00, "currency": "USD"},
                {"po_number": "4500001235", "vendor": "TechSupply GmbH", "amount": 8750.00, "currency": "EUR"},
            ],
        }

    elif name == "get_user_info":
        user_id = arguments["user_id"]
        result = {
            "user_id": user_id,
            "name": "John Doe",
            "email": f"{user_id}@company.com",
            "roles": ["MM_PURCHASER", "FI_APPROVER"],
            "cost_center": "CC1000",
        }
    else:
        result = {"error": f"Unknown tool: {name}"}

    return [TextContent(type="text", text=json.dumps(result, indent=2))]


async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
