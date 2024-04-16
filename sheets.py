import gspread
from oauth2client.service_account import ServiceAccountCredentials
from constants import tx_values
from dotenv import load_dotenv
import os

load_dotenv()
scope = ['https://spreadsheets.google.com/feeds',
                'https://www.googleapis.com/auth/drive']

creds = ServiceAccountCredentials.from_json_keyfile_name('creds.json', scope)
client = gspread.authorize(creds)
spreadsheet = client.open(os.getenv('SPREADSHEET_NAME'))
worksheet = spreadsheet.worksheet(os.getenv('WORKSHEET_NAME'))

def send_to_sheets(body):
    data_list = []
    for value in tx_values:
        if value == "valor_transaccion":
            data_list.append(int(body.get(value, 0)))
        else:
            data_list.append(body.get(value, ""))
    data = data_list
    # Insertar datos en la última fila del sheet
    worksheet.append_row(data)

