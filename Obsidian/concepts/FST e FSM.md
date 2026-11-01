FSM (Finite State Machine) e FST (Finite State Transducer) são modelos matemáticos usados na ciência da computação, que utilizam o conceito de estado de máquina. Embora ambos se baseiem em estados finitos, a principal diferença está na saída que produzem. 

FMS (Finite State Machine)

- Uma FSM, ou máquina de estados finitos, é um modelo que pode estar em exatamente um de um número finito de estados a qualquer momento.
- Cada estado representa uma situação específica no processo, e as transições entre os estados dependem de eventos (entradas) e do estado atual da máquina.
- É uma ferramenta fundamental para o sequenciamento de tarefas em lógica digital, automação e programação.
- Existem dois tipos principais de FMS, que se diferenciam pela forma como a saída é gerada:
    - **Máquina de Moore**: A saída depende exclusivamente do estado atual da máquina. Mudar de estado muda a saída.
    - **Máquina de Mealy**: A saída depende tanto do estado atual quanto da entrada que causou a transição. 

FST (Finite State Transducer)

- Um FST, ou transdutor de estados finitos, é um tipo específico de máquina de estados finitos que, além de reconhecer a entrada e mudar de estado, **gera uma saída**.
- Ao contrário da FSM, que pode simplesmente indicar a conclusão de uma tarefa, o FST é projetado para produzir uma nova informação (a saída) para cada sequência de transições.
- É usado para traduzir uma sequência de símbolos de entrada em uma sequência de símbolos de saída. Um exemplo clássico é a máquina de Turing, um modelo de computação que opera com base nesse conceito.