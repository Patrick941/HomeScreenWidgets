import requests
import re
import plistlib
import csv
from bs4 import BeautifulSoup
import datetime
import sys
import os

def get_stock_price(stock_symbol):
    url = f"https://finance.yahoo.com/quote/{stock_symbol}"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.5',  # Specify language preference
    }
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            soup = BeautifulSoup(response.content, 'html.parser')
            # Extracting the current stock price per share
            price_tag = soup.find('fin-streamer', class_='livePrice')
            if price_tag:
                price_span = price_tag.find('span')  # Locate the span inside the fin-streamer
                if price_span:
                    price = float(price_span.text.strip())  # Extracting the price as float
                else:
                    print("Price span not found.")
                    return None, None
            else:
                print("Price tag not found.")
                return None, None

            # Extracting the time of day
            time = datetime.datetime.now().strftime("%I:%M %p")

            return price, time
        else:
            print(f"Failed to retrieve data for {stock_symbol}. Status code: {response.status_code}")
            return None, None
    except requests.exceptions.RequestException as e:
        print(f"An error occurred while fetching data for {stock_symbol}: {e}")
        return None, None


def main():
    stock_symbols = []
    amount = []
    starting_price = []

    # Open the CSV file and read the data
    # Check if the command line argument is provided
    csv_file_path = "/Users/patrick/Desktop/PatricksHomeScreen/PythonScripts/StockInfo.csv"

    with open(csv_file_path, newline='') as csvfile:
        reader = csv.reader(csvfile)
        # Rest of the code...
        reader = csv.reader(csvfile)
        for row in reader:
            # Extract data from each row and append it to the respective lists
            stock_symbols.append(row[0])
            amount.append(float(row[1]))  # Convert to float if numerical data
            starting_price.append(float(row[2]))  # Convert to float if numerical data

    Output = {}

    for index, symbol in enumerate(stock_symbols):
        price, time = get_stock_price(symbol)
        Output[symbol] = {}
        Output[symbol]['Symbol'] = symbol
        Output[symbol]['Price'] = price
        Output[symbol]['Time'] = time
        Output[symbol]['Original Price'] = starting_price[index]
        Output[symbol]['Value'] = float(price) * amount[index]
        Output[symbol]['Original Value'] = float(starting_price[index]) * amount[index]
        Output[symbol]['Margin'] = ((float(price) - float(starting_price[index])) / float(starting_price[index])) * 100
        stock = Output[symbol]
        print(f"Stock Details for {symbol}: Symbol: {stock['Symbol']} Current Price: {stock['Price']} Time: {stock['Time']} Original Price: {stock['Original Price']} Value: {stock['Value']} Original Value: {stock['Original Value']} Margin: {stock['Margin']}%\n")
    
    output_directory = '/Users/patrick/Documents'
    output_file = os.path.join(output_directory, 'output.plist')


    # Writing to the file
    with open(output_file, 'wb') as plistfile:
        plistlib.dump(Output, plistfile)
        exit()

if __name__ == "__main__":
    main()
