prompt = """
Dame un objeto json con los valores de la transacción. No uses caracteres especiales y convierte el numero a numerico. Agrega un campo que sea la categoría según el lugar de la compra. Que todas las llaves queden en minuscula y sin espacio
Los keys deben ser:
{
  "fecha": ,
  "hora": ,
  "valor_transaccion":,
  "clase_movimiento": ,
  "lugar_transaccion": ,
  "categoria": ,
  "tarjeta":,
  "banco":,
}
El formato de fecha debe ser yyyy-mm-dd
En la tarjeta espero el número de la tarjeta
En categoría pon una acorde al lugar de la transacción
En banco el banco donde se hizo la transaccion
Solo dame el JSON
"""

tx_values = ["fecha","hora","valor_transaccion","clase_movimiento","lugar_transaccion","categoria","tarjeta","banco"]