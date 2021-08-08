// Nombre: Nicolas Vasquez //<>// //<>// //<>// //<>// //<>//
// Fecha: 08/08/2021

Flock flock;

void setup() {
  size(700, 500);
  background(0);
  frameRate(200);
  rectMode(CENTER);

  stroke(178, 102, 255);
  line(0, 0, 600, 226);
  line(0, 500, 600, 274);

  flock = new Flock();
  // Aleatorio
  //for (int i = 0; i < 80; i++) {
  //  flock.addPerson(new Person(flock.people));
  //}

  // Determinista
  for (int i = 0; i < 8; i++) {
    for (int j = 0; j < 10; j++) {
      flock.addPerson(new Person(new PVector(50 + i*22, 150 + 22*j)));
    }
  }
}

void draw() {
  //scale(1, -1);
  //translate(0, -height);
  background(0);
  stroke(178, 102, 255);
  line(0, 0, 600, 226);
  line(0, 500, 600, 274);

  flock.run();
}

// Puntos de la linea

final PVector L1_1 = new PVector(0, 0);
final PVector L1_2 = new PVector(600, 226);
final PVector L2_1 = new PVector(0, 500);
final PVector L2_2 = new PVector(600, 274);

final PVector EXIT_SUP = new PVector(600, 239);
final PVector EXIT_INF = new PVector(600, 261);

// Constantes
final float R = 80;
final float A = 25.0;
final float B = 0.08;
final float k = 750;
final float kappa = 3000;
final float v_zero = 5.0;
final float tau = 0.5;
final float delta_t = 0.5;

final float MAX_VELOCITY = 10.0;
final float MAX_FORCE = 0.3;

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
  // Vector unitario
  dx = dx/mag;
  dy = dy/mag;

  // Obtiene el punto
  double lamda = (dx * (p3.x - p1.x)) + (dy * (p3.y - p1.y));
  float x4 = (float) ((dx * lamda) + p1.x);
  float y4 = (float) ((dy * lamda) + p1.y);
  return new PVector(x4, y4);
}

class Flock {
  public ArrayList<Person> people;

  Flock() {
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

  void update(PVector force) {
    v = PVector.add(v, PVector.mult(force, delta_t));
    v.limit(MAX_VELOCITY);
    p = PVector.add(p, PVector.mult(v, delta_t));
  }

  PVector calc_force(ArrayList<Person> people) {
    PVector same = f_same();
    PVector person = f_person(people);
    PVector wall = f_wall();
    return PVector.add(same, PVector.add(person, wall));
    //return same;
  }

  PVector calc_e() {
    if (p.y > 231 && p.y < 279) {
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
    PVector pw = point_perpendicular(p1, p2, p);
    
    float d_iw = PVector.sub(p, pw).mag();
    PVector n_iw = normalize(p, pw);
    
    PVector f_repulsion = PVector.mult(n_iw, A*exp(-(d_iw - r)/B));
    PVector f_corporal = PVector.mult(n_iw, 2*k*(r - d_iw));
    PVector f_friccion = PVector.mult(p_normalize(n_iw), kappa*(r - d_iw) * v_tangential(pw));
    
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
    update(total_force);
  };

  void render() {
    fill(178, 102, 255);
    pushMatrix();
    circle(p.x, p.y, r*2);
    popMatrix();
  }
}
