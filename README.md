# Security Review Challenge - TokenSale

## Objetivo

Encontre todas as vulnerabilidades no contrato `src/TokenSale.sol`.

Quando terminar, descriptografe o arquivo `vulnerabilities.enc` para verificar suas respostas.

---

## Logica de Negocios

O contrato `TokenSale` implementa uma venda de tokens com as seguintes regras:

### Regras de Negocio

1. **Whitelist**: Apenas usuarios na whitelist podem comprar tokens
   - Somente o owner pode adicionar usuarios a whitelist

2. **Compra de Tokens**:
   - O preco por token e 1 ETH (configuravel pelo owner)
   - Usuario envia ETH e recebe tokens proporcionalmente
   - A venda so funciona quando `saleActive = true`

3. **Transferencia**: Usuarios podem transferir tokens entre si

4. **Reembolso**: Usuarios podem devolver tokens e receber ETH de volta
   - O valor devolvido e calculado pelo preco atual do token
   - Usuario so pode pedir reembolso de tokens que possui

5. **Administracao (somente owner)**:
   - Alterar preco do token
   - Sacar fundos do contrato
   - Pausar a venda em emergencias

---

## Como Verificar Suas Respostas

```bash
openssl enc -aes-256-cbc -d -pbkdf2 -in vulnerabilities.enc -out respostas.txt -pass pass:CHAVE
```

---

## Comandos Uteis

```bash
# Compilar
forge build

# Rodar testes
forge test -vv

# Ver cobertura
forge coverage
```
