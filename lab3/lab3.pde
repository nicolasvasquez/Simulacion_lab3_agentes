// Nombre: Nicolas Vasquez //<>// //<>//
// Fecha: 08/08/2021

// Constantes para modo de ejecucion

// Genera particulas en posiciones aleatorias dentro del espacio asignado.
// Al usar false, se generan de forma determinista.
final boolean RANDOM_GENERATE = true;
// Al salir una particula de la pantalla vuelve por el otro lado.
// Al usar false simplemente se eliminan
final boolean INFINITE_LOOP = false;

// Velocidad y fuerza maxima. De estas constantes depende el comportamiento de los agentes.
final float MAX_VELOCITY = 10.0;
final float MAX_FORCE = 3.5;

// Constantes
final float R = 80;
final float A = 25.0;
final float B = 0.08;
final float k = 750;
final float kappa = 3000;
final float v_zero = 5.0;
final float tau = 0.5;
final float delta_t = 0.5;
final int MAX_PEOPLE = 80;

// Puntos de las paredes

final PVector L1_1 = new PVector(0, 0);
final PVector L1_2 = new PVector(600, 226);
final PVector L2_1 = new PVector(0, 500);
final PVector L2_2 = new PVector(600, 274);

final PVector EXIT_SUP = new PVector(600, 239);
final PVector EXIT_INF = new PVector(600, 261);

Group group;

void setup() {
  size(700, 500);
  frameRate(60);
  rectMode(CENTER);

  background(68, 0, 40);
  stroke(203, 135, 175);
  line(0, 0, 600, 226);
  line(0, 500, 600, 274);

  group = new Group();

  // Aleatorio
  if (RANDOM_GENERATE) {
    for (int i = 0; i < MAX_PEOPLE; i++) {
      group.addPerson(new Person(group.people));
    }
  } else {
    // Determinista
    for (int i = 0; i < MAX_PEOPLE/10; i++) {
      for (int j = 0; j < 10; j++) {
        group.addPerson(new Person(new PVector(50 + i*22, 150 + 22*j)));
      }
    }
  }
}

void draw() {
  background(68, 0, 40);
  stroke(203, 135, 175);
  line(0, 0, 600, 226);
  line(0, 500, 600, 274);

  group.run();
}

void mousePressed() {
  group.addPerson(new Person(new PVector(mouseX, mouseY)));
}

ArrayList<Person> copy(ArrayList<Person> people) {
  ArrayList<Person> aux = new ArrayList<Person>();

  for (Person pp : people) {
    aux.add(new Person(pp.p, pp.v));
  }

  return aux;
}

PVector normalize(PVector v1, PVector v2) {
  if (PVector.dist(v1, v2) == 0) return new PVector(0, 0);
  PVector aux = PVector.sub(v1, v2);
  return PVector.div(aux, aux.mag());
}

PVector p_normalize(PVector v1) {
  PVector aux = new PVector(-v1.y, v1.x);
  if (aux.mag() == 0 ) return new PVector(0, 0);
  return PVector.div(aux, aux.mag());
}

PVector point_perpendicular(PVector p1, PVector p2, PVector p3) {
  double dx = p2.x - p1.x;
  double dy = p2.y - p1.y;
  double mag = Math.sqrt(dx*dx + dy*dy);
  if (mag == 0) return new PVector(0, 0);
  // Vector unitario
  dx = dx/mag;
  dy = dy/mag;

  // Obtiene el punto
  double lamda = (dx * (p3.x - p1.x)) + (dy * (p3.y - p1.y));
  float x4 = (float) ((dx * lamda) + p1.x);
  float y4 = (float) ((dy * lamda) + p1.y);
  return new PVector(x4, y4);
}

class Group {
  public ArrayList<Person> people;

  Group() {
    people = new ArrayList<Person>();
  }

  void addPerson(Person  p) {
    people.add(p);
  }

  void run() {
    ArrayList<Person> now = copy(people);
    for (Person p : people) {
      p.run(now);
    }
  }
}

class Person {
  float r;
  PVector p, v;

  Person(ArrayList<Person> people) {
    r = 10;
    p = p_random(people);
    v = new PVector(0, 0);
  }

  Person(PVector position, PVector velocity) {
    r = 10;
    p = position.copy();
    v = velocity.copy();
  }

  Person(PVector position) {
    r = 10;
    p = position.copy();
    v = new PVector(0, 0);
  }

  void update(ArrayList<Person> people, PVector force) {
    v = PVector.add(v, PVector.mult(force, delta_t));
    v.limit(MAX_VELOCITY);
    p = PVector.add(p, PVector.mult(v, delta_t));

    if (p.x > 700) {
      if (INFINITE_LOOP) {
        p = p.set(0, p.y);
      }
    }
  }

  PVector calc_force(ArrayList<Person> people) {
    PVector fs = f_same();
    PVector fp = f_person(people);
    PVector fw = f_wall();
    return PVector.add(fs, PVector.add(fp, fw));
  }

  PVector calc_e() {
    if ((p.y > 236 && p.y < 284) || p.x > 610) {
      return new PVector(1, 0);
    }
    if (p.y <= 231) {
      return normalize(EXIT_SUP, p);
    }
    return normalize(EXIT_INF, p);
  }

  PVector f_same() {
    PVector total = PVector.mult(PVector.sub(PVector.mult(calc_e(), v_zero), v), 1/tau);
    total.limit(MAX_FORCE);
    return total;
  }

  PVector f_person(ArrayList<Person> people) {
    PVector acum_repulsion = new PVector(0, 0);
    PVector acum_corporal = new PVector(0, 0);
    PVector acum_friccion = new PVector(0, 0);
    for (Person other : people) {
      float d_ij = PVector.sub(p, other.p).mag();
      float r_ij = r + other.r;
      PVector n_ij = normalize(p, other.p);

      acum_repulsion.add(PVector.mult(n_ij, A*exp(-1*(d_ij - r_ij)) / B));

      if (d_ij <= r_ij) {
        acum_corporal.add(PVector.mult(n_ij, 2*k*(r_ij - d_ij)));
        acum_friccion.add(PVector.mult(p_normalize(n_ij), kappa*(r_ij - d_ij) * v_tangential(other)));
      }
    }

    acum_repulsion.limit(MAX_FORCE);
    acum_corporal.limit(MAX_FORCE);
    acum_friccion.limit(MAX_FORCE);

    return PVector.add(PVector.add(acum_repulsion, acum_corporal), acum_friccion);
  }

  PVector f_wall() {
    PVector f_wall1 = calc_wall(L1_1, L1_2);
    PVector f_wall2 = calc_wall(L2_1, L2_2);
    return PVector.add(f_wall1, f_wall2);
  }

  PVector calc_wall(PVector p1, PVector p2) {
    PVector f_corporal = new PVector(0, 0);
    PVector f_friccion = new PVector(0, 0);

    PVector pw = point_perpendicular(p1, p2, p);
    float d_iw = PVector.sub(p, pw).mag();
    PVector n_iw = normalize(p, pw);

    PVector f_repulsion = PVector.mult(n_iw, A*exp(-(d_iw - r)/B));

    if (PVector.dist(p, pw) <= r) {
      f_corporal = PVector.mult(n_iw, 2*k*(r - d_iw));
      f_friccion = PVector.mult(p_normalize(n_iw), kappa*(r - d_iw) * v_tangential(pw));
    }

    // Caso de borde cuando el numero de la operacion es mayor al float max value.
    // Se deja el numero mas grande posible. Luego se regularizara con los limites.
    if (f_repulsion.x == Float.POSITIVE_INFINITY || f_repulsion.x == Float.NEGATIVE_INFINITY) {
      f_repulsion = PVector.mult(n_iw, Float.MAX_VALUE);
    }

    f_repulsion.limit(MAX_FORCE);
    f_corporal.limit(MAX_FORCE);
    f_friccion.limit(MAX_FORCE);

    return PVector.add(f_repulsion, PVector.add(f_corporal, f_friccion));
  }

  float v_tangential(Person other) {
    PVector aux = PVector.sub(other.v, v);
    return aux.dot(p_normalize(normalize(p, other.p)));
  }

  float v_tangential(PVector wall) {
    return v.dot(p_normalize(normalize(p, wall)));
  }

  PVector p_random(ArrayList<Person> people) {
    boolean flag = true;
    PVector position = new PVector();
    while (flag) {
      flag = false;
      position.set(random(10, 230), random(110, 390));

      for (Person other : people) {
        if (PVector.dist(position, other.p) <= 20) flag = true;
      }
    }
    return position;
  }

  void run(ArrayList<Person> people) {
    render();
    PVector total_force = calc_force(people);
    update(people, total_force);
  };

  void render() {
    fill(135, 45, 98);
    stroke(169, 84, 134);
    pushMatrix();
    circle(p.x, p.y, r*2);
    popMatrix();
  }
}
