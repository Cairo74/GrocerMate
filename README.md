# GrocerMate 🛒

**GrocerMate** é o seu assistente social para compras de supermercado. Crie e compartilhe listas de compras com amigos, descubra novos produtos em uma comunidade vibrante e nunca mais esqueça um item!

---

## ✨ Funcionalidades

- **Listas de Compras Inteligentes**: Crie, gerencie e compartilhe listas de compras detalhadas.
- **Comunidade Ativa**: Interaja com outros usuários, poste suas descobertas e comente nas publicações da comunidade.
- **Modelos (Templates)**: Crie modelos de listas para compras recorrentes (churrasco de fim de semana, compras do mês, etc).
- **Feed Social**: Um feed de blog para compartilhar dicas, receitas e experiências.
- **Sistema de Amigos**: Adicione amigos, compartilhe listas e interaja de forma privada.
- **Perfis de Usuário**: Personalize seu perfil, adicione uma foto e veja as atividades dos seus amigos.
- **Notificações em Tempo Real**: Seja notificado sobre novas amizades, comentários e outras interações.
- **Tema Claro e Escuro**: Alterne entre os modos claro e escuro para melhor conforto visual.

---

## 🛠️ Tecnologias Utilizadas

- **Frontend**: [Flutter](https://flutter.dev/)
- **Backend & Autenticação**: [Supabase](https://supabase.io/)
- **Notificações Push**: [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- **Design e Componentes**: Material Design 3

---

## 🚀 Como Começar

Siga estas instruções para configurar e rodar o projeto em seu ambiente local.

### Pré-requisitos

- **Flutter SDK**: Certifique-se de que você tem o Flutter instalado. Para mais informações, acesse a [documentação oficial do Flutter](https://flutter.dev/docs/get-started/install).
- Você precisará das keys do supabase para conseguir rodar localmente!

### Instalação

1.  **Clone o repositório:**
    ```sh
    git clone https://github.com/seu-usuario/grocermate.git
    cd grocermate
    ```

2.  **Crie e configure o arquivo de ambiente:**
    Copie o arquivo de exemplo `.env.example` para um novo arquivo chamado `.env` e adicione as chaves do Supabase.

    ```sh
    cp .env.example .env
    ```

    Seu arquivo `.env` deve se parecer com isto:
    ```
    SUPABASE_URL=SUA_URL_DO_SUPABASE
    SUPABASE_ANON_KEY=SUA_CHAVE_ANON_DO_SUPABASE
    ```

3.  **Instale as dependências:**
    ```sh
    flutter pub get
    ```

4.  **Rode o aplicativo:**
    ```sh
    flutter run
    ```


