#!/usr/bin/env python3
"""
Kubecost API Script - Query allocation data for a single day (2 days ago)
Outputs data in CSV format
"""

import requests
from datetime import datetime, timedelta
from urllib.parse import urlencode
import sys

def get_kubecost_data():
    """
    Query Kubecost API for allocation data from 2 days ago
    """
    
    # Calculate the date 2 days ago
    target_date = datetime.now() - timedelta(days=2)
    
    # Format the window parameter for a single day
    # Kubecost expects format: YYYY-MM-DDTHH:MM:SSZ,YYYY-MM-DDTHH:MM:SSZ
    start_time = target_date.strftime("%Y-%m-%dT00:00:00Z")
    end_time = target_date.strftime("%Y-%m-%dT23:59:59Z")
    window = f"{start_time},{end_time}"
    
    # Base URL
    base_url = "https://$kubecostURL/model/allocation/summary"
    
    # Query parameters
    params = {
        'accumulate': 'true',
        'aggregate': 'namespace,pod',
        'chartType': 'costovertime',
        'costUnit': 'daily',
        'external': 'false',
        'filter': '',
        'idle': 'true',
        'idleByNode': 'false',
        'includeSharedCostBreakdown': 'false',
        'shareCost': '0',
        'shareIdle': 'false',
        'shareLabels': '',
        'shareNamespaces': '',
        'shareSplit': 'weighted',
        'shareTenancyCosts': 'false',
        'window': window,
        'offset': '0',
        'limit': '25',
        'format': 'csv'  # Request CSV format from API
    }
    
    # Construct the full URL
    url = f"{base_url}?{urlencode(params)}"
    
    print(f"Querying Kubecost for date: {target_date.strftime('%Y-%m-%d')}")
    print(f"URL: {url}")
    print("-" * 80)
    
    try:
        # Make the API request
        response = requests.get(url, timeout=30)
        response.raise_for_status()  # Raise an exception for bad status codes
        
        # Print response summary
        print("API Response Status: SUCCESS")
        print(f"Response Size: {len(response.content)} bytes")
        
        # Print first few lines of CSV data
        print("\nResponse Data Preview:")
        print(response.text.split('\n')[:5])  # Show first 5 lines
        
        return response.text
        
    except requests.exceptions.RequestException as e:
        print(f"Error making API request: {e}")
        return None
    except Exception as e:
        print(f"Unexpected error: {e}")
        return None

def main():
    """
    Main function to execute the Kubecost API query
    """
    print("Kubecost API Query Script")
    print("=" * 50)
    
    # Execute the API query
    result = get_kubecost_data()
    
    if result is not None:
        print("\n" + "=" * 50)
        print("Query completed successfully!")
        
        # Save to CSV
        target_date = (datetime.now() - timedelta(days=2)).strftime('%Y-%m-%d')
        csv_filename = f"kubecost_data_{target_date}.csv"
        
        try:
            # Save CSV directly from API response
            with open(csv_filename, 'w') as f:
                f.write(result)
            print(f"Data saved to CSV: {csv_filename}")
                
        except Exception as e:
            print(f"Warning: Could not save to file: {e}")
            sys.exit(1)
    else:
        print("\nQuery failed!")
        sys.exit(1)

if __name__ == "__main__":
    main() 