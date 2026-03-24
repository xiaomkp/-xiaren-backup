#!/usr/bin/env python3
"""
BTC Cross-Exchange Price Monitor
监控 Binance、OKX、Huobi 三个交易所的 BTC/USDT 价格，计算价差和预估利润
"""

import requests
import time
import json
from datetime import datetime

# ========== 配置 ==========
CHECK_INTERVAL = 30  # 秒
FEE_RATE = 0.002     # 手续费 0.2%
TRADE_AMOUNT = 1000  # 模拟交易金额（USDT）
# ==========================

BINANCE_API = "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT"
OKX_API = "https://www.okx.com/api/v5/market/ticker?instId=BTC-USDT"
HUOBI_API = "https://api.huobi.pro/market/detail/merged?symbol=btcusdt"

EXCHANGES = {
    "Binance": BINANCE_API,
    "OKX": OKX_API,
    "Huobi": HUOBI_API,
}


def fetch_price_binance():
    try:
        r = requests.get(BINANCE_API, timeout=10)
        r.raise_for_status()
        data = r.json()
        return float(data["price"])
    except Exception as e:
        print(f"[Binance] 获取价格失败: {e}")
        return None


def fetch_price_okx():
    try:
        r = requests.get(OKX_API, timeout=10)
        r.raise_for_status()
        data = r.json()
        if data.get("code") != "0":
            print(f"[OKX] API错误: {data}")
            return None
        return float(data["data"][0]["last"])
    except Exception as e:
        print(f"[OKX] 获取价格失败: {e}")
        return None


def fetch_price_huobi():
    try:
        r = requests.get(HUOBI_API, timeout=10)
        r.raise_for_status()
        data = r.json()
        if data.get("status") != "ok":
            print(f"[Huobi] API错误: {data}")
            return None
        return float(data["tick"]["close"])
    except Exception as e:
        print(f"[Huobi] 获取价格失败: {e}")
        return None


def calculate_arb(prices: dict):
    """
    计算所有交易对之间的套利机会
    返回: list of (buy_exchange, sell_exchange, buy_price, sell_price, profit_usdt, profit_pct)
    """
    opportunities = []
    exchanges = list(prices.keys())
    for i, buy_ex in enumerate(exchanges):
        for j, sell_ex in enumerate(exchanges):
            if i == j:
                continue
            buy_price = prices[buy_ex]
            sell_price = prices[sell_ex]

            # 买入 -> 卖出手续费
            buy_fee = buy_price * FEE_RATE
            sell_fee = sell_price * FEE_RATE

            # 实际买入数量 (USDT 扣除手续费后)
            btc_bought = (TRADE_AMOUNT - TRADE_AMOUNT * FEE_RATE) / (buy_price + buy_fee)

            # 卖出获得 USDT
            revenue = btc_bought * (sell_price - sell_fee)
            profit = revenue - TRADE_AMOUNT
            profit_pct = (profit / TRADE_AMOUNT) * 100

            opportunities.append({
                "buy_ex": buy_ex,
                "sell_ex": sell_ex,
                "buy_price": buy_price,
                "sell_price": sell_price,
                "profit_usdt": profit,
                "profit_pct": profit_pct,
            })

    # 按利润排序
    opportunities.sort(key=lambda x: x["profit_usdt"], reverse=True)
    return opportunities


def print_divider():
    print("=" * 70)


def format_profit(p):
    if p > 0:
        return f"\033[92m${p:.4f}\033[0m"   # 绿色
    elif p < 0:
        return f"\033[91m${p:.4f}\033[0m"   # 红色
    else:
        return f"${p:.4f}"


def main():
    print_divider()
    print("  BTC 跨交易所价格监控器  |  检查间隔: 30秒  |  手续费: 0.2%  |  模拟金额: $1000 USDT")
    print_divider()

    while True:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"\n[{ts}] 正在抓取价格...")

        prices = {}

        # 抓取所有交易所价格
        prices["Binance"] = fetch_price_binance()
        prices["OKX"] = fetch_price_okx()
        prices["Huobi"] = fetch_price_huobi()

        # 检查是否有失败
        failed = [k for k, v in prices.items() if v is None]
        if failed:
            print(f"[!] 以下交易所获取失败: {', '.join(failed)}")
            print("    5秒后重试...")
            time.sleep(5)
            continue

        # 打印价格
        print()
        print_divider()
        print("  各交易所 BTC/USDT 价格")
        print_divider()
        price_list = [(k, v) for k, v in prices.items()]
        price_list.sort(key=lambda x: x[1], reverse=True)

        for rank, (ex, price) in enumerate(price_list, 1):
            arrow = "📈" if rank == 1 else ("📉" if rank == len(price_list) else "  ")
            print(f"  {arrow} {ex:<10} ${price:,.2f}")

        # 计算并显示价差
        max_price_ex = max(prices, key=prices.get)
        min_price_ex = min(prices, key=prices.get)
        spread = prices[max_price_ex] - prices[min_price_ex]
        spread_pct = (spread / prices[min_price_ex]) * 100

        print()
        print_divider()
        print(f"  📊 最高价: {max_price_ex} ${prices[max_price_ex]:,.2f}")
        print(f"  📊 最低价: {min_price_ex} ${prices[min_price_ex]:,.2f}")
        print(f"  📊 绝对价差: ${spread:.2f}")
        print(f"  📊 价差比例: {spread_pct:.4f}%")
        print_divider()

        # 计算套利机会
        opps = calculate_arb(prices)
        best = opps[0]

        print()
        print_divider()
        print("  🔍 套利机会分析（买入 → 卖出）")
        print_divider()

        for opp in opps:
            p = opp["profit_usdt"]
            flag = "✅ 有利润!" if p > 0 else "❌ 无利润"
            print(
                f"  {flag}  买入 {opp['buy_ex']:<7} → 卖出 {opp['sell_ex']:<7} | "
                f"买 ${opp['buy_price']:,.2f} 卖 ${opp['sell_price']:,.2f} | "
                f"利润: {format_profit(p)} ({opp['profit_pct']:.4f}%)"
            )

        print_divider()

        # 醒目提醒
        if best["profit_usdt"] > 0:
            print()
            print("  🚨🚀🚨🚀🚨🚀🚨🚀🚨🚀🚨🚀🚨🚀🚨🚀🚨🚀🚨")
            print(f"  🚨  发现套利机会！利润: {format_profit(best['profit_usdt'])} ({best['profit_pct']:.4f}%)")
            print(f"  🚨  在 {best['buy_ex']} 买入 BTC，在 {best['sell_ex']} 卖出 BTC")
            print(f"  🚨  买入价: ${best['buy_price']:,.2f} | 卖出价: ${best['sell_price']:,.2f}")
            print("  🚨  ⚠️  注意：实际利润可能受滑点、流动性、市场深度影响！")
            print("  🚨🚀🚨🚀🚨🚀🚨🚀🚨🚀🚨🚀🚨🚀🚨🚀🚨🚀🚨")
            print()

        print(f"\n  ⏳ 下次检查: {CHECK_INTERVAL} 秒后...")

        time.sleep(CHECK_INTERVAL)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n  监控已停止。")
