<template>
  <div>
    <app-nav></app-nav>
    <div class="container">
      <spinner v-show="isProcessing" message="Processing..."></spinner>
      <div class="row">
        <div class="col-sm-12 text-left">
          <h1>
            TODOs
            <transition name="fade">
              <small v-if="total">({{ total }})</small>
            </transition>
          </h1>
        </div>
      </div>

      <div class="row">
        <div class="col-sm-12">
          <div class="form-control-feedback">
            <span class="text-danger align-middle">
              {{ errorMessage }}
            </span>
          </div>
        </div>
      </div>

      <div class="row">
        <div class="col-sm-10">
          <input
            type="text"
            class="form-control"
            v-model="newTask"
            @keyup.enter="addTask"
            placeholder="New task"
          />
        </div>
        <div class="col-sm-2 text-right">
          <button type="submit" class="btn btn-primary" @click="addTask">
            Add todo
          </button>
        </div>
      </div>

      <div class="row">
        <transition-group
          name="fade"
          tag="ul"
          class="no-bullet list-group col-sm-12 my-4"
        >
          <todo-item
            v-for="(todo, index) in tasks"
            @remove="removeTask(index)"
            :todo="todo"
            :key="index"
          ></todo-item>
        </transition-group>
      </div>
    </div>
  </div>
</template>

<script>
import AppNav from "@/components/AppNav";
import TodoItem from "@/components/TodoItem";
import Spinner from "@/components/common/Spinner";
import { createAPICircuitBreaker } from "@/circuit-breaker";

// Circuit Breaker para operaciones de TODOs
const todosCircuitBreaker = createAPICircuitBreaker("Todos");

export default {
  name: "todos",
  components: { AppNav, TodoItem, Spinner },
  props: {
    tasks: {
      default: function () {
        return [];
      },
    },
  },
  data() {
    return {
      isProcessing: false,
      errorMessage: "",
      newTask: "",
    };
  },
  created() {
    this.loadTasks();
  },
  computed: {
    total() {
      return this.tasks.length;
    },
  },
  methods: {
    loadTasks() {
      this.isProcessing = true;
      this.errorMessage = "";

      // Usar Circuit Breaker para cargar TODOs
      todosCircuitBreaker
        .call(
          () => this.$http.get("/todos"),
          () => {
            // Fallback: mostrar mensaje y datos en caché si los hay
            console.warn("TODOs service is temporarily unavailable");
            return Promise.resolve({ body: [] }); // Lista vacía como fallback
          }
        )
        .then((response) => {
          this.tasks = []; // Limpiar lista actual
          for (var i in response.body) {
            this.tasks.push(response.body[i]);
          }
          this.isProcessing = false;
        })
        .catch((error) => {
          this.isProcessing = false;
          this.errorMessage =
            "Unable to load TODOs. Service may be temporarily unavailable.";
          console.error("Error loading tasks:", error);
        });
    },

    addTask() {
      if (this.newTask) {
        this.isProcessing = true;
        this.errorMessage = "";

        var task = {
          content: this.newTask,
        };

        this.$http.post("/todos", task).then(
          (response) => {
            this.newTask = "";
            this.isProcessing = false;
            this.tasks.push(task);
          },
          (error) => {
            this.isProcessing = false;
            this.errorMessage =
              JSON.stringify(error.body) + ". Response code: " + error.status;
          }
        );
      }
    },

    removeTask(index) {
      const item = this.tasks[index];

      this.isProcessing = true;
      this.errorMessage = "";

      this.$http.delete("/todos/" + item.id).then(
        (response) => {
          this.isProcessing = false;
          this.tasks.splice(index, 1);
        },
        (error) => {
          this.isProcessing = false;
          this.errorMessage =
            JSON.stringify(error.body) + ". Response code: " + error.status;
        }
      );
    },
  },
};
</script>
